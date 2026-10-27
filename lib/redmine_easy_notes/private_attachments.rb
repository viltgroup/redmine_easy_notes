# frozen_string_literal: true

module RedmineEasyNotes
  # Files added on a private note belong to that note, so that a team-only
  # discussion does not show up to everyone else as new files on the issue.
  #
  # Core keeps a private note to its text alone: Journal#split_private_notes
  # moves every detail, attachments included, into a separate public journal
  # ("File added"), so the file is listed, mailed and downloadable as if it had
  # been added publicly. With Settings.private_attachments? on:
  #
  # * the attachment details stay on the private journal, and only the other
  #   changes are split off as core does;
  # * such a file can only be opened by its note's author and by users with
  #   view_private_notes, the same people who can see the note;
  # * the issue's Files section leaves it out, for everyone.
  #
  # Nothing is stored apart from where core already keeps it: a file is private
  # because its "added" detail sits on a private journal. Switching the setting
  # off makes these files visible and listed again. Files that core already
  # split off before this existed are on public journals and stay public.
  module PrivateAttachments
    # Ids of the files added on the issue's private notes, as strings, since
    # that is how JournalDetail#prop_key holds them.
    def self.attachment_ids(issue)
      JournalDetail.joins(:journal).
        where(property: 'attachment',
              journals: {journalized_type: 'Issue', journalized_id: issue.id, private_notes: true}).
        where.not(value: nil).
        pluck(:prop_key)
    end

    # The private note the attachment was added on, or nil.
    def self.private_journal_for(attachment)
      Journal.joins(:details).
        where(journalized_type: 'Issue', journalized_id: attachment.container_id, private_notes: true,
              journal_details: {property: 'attachment', prop_key: attachment.id.to_s}).
        where.not(journal_details: {value: nil}).
        first
    end

    # Mirrors Journal.visible: the note's author, or view_private_notes.
    def self.visible?(attachment, user)
      return true unless Settings.private_attachments?
      return true unless attachment.container_type == 'Issue' && attachment.container_id

      journal = private_journal_for(attachment)
      journal.nil? || journal.user_id == user.id ||
        user.allowed_to?(:view_private_notes, journal.project)
    end

    module JournalPatch
      private

      # Core's split, except that attachment details stay on the private note.
      # Falls back to core whenever there is no file to keep.
      def split_private_notes
        return super unless Settings.private_attachments? && private_notes? && notes.present?

        files, changes = details.partition { |detail| detail.property == 'attachment' }
        return super if files.empty?

        if changes.any?
          journal = Journal.new(:journalized => journalized, :user => user, :notes => nil, :private_notes => false)
          journal.details = changes
          journal.save
          self.created_on = journal.created_on
        end
        self.details = files
        true
      end
    end

    # Attachment#visible? is what AttachmentsController checks before showing,
    # downloading or thumbnailing a file, so this one check covers all of them.
    module AttachmentPatch
      def visible?(user = User.current)
        super && PrivateAttachments.visible?(self, user)
      end
    end

    module AttachmentsHelperPatch
      # Core's link_to_attachments, without the files of private notes, for the
      # Files section of issues/show.html.erb, its only caller for an issue.
      # The issue's own attachments association is left whole: inline images in
      # the private note itself are resolved through it.
      def link_to_attachments(container, options = {})
        return super unless container.is_a?(Issue) && Settings.private_attachments?

        hidden = PrivateAttachments.attachment_ids(container)
        return super if hidden.empty?

        options.assert_valid_keys(:author, :thumbnails)
        attachments = container.attachments.preload(:author).to_a.reject { |a| hidden.include?(a.id.to_s) }
        # The template has already written the section's <hr /> and heading,
        # because it checks the whole association. With nothing left to list,
        # remove them rather than leave an empty "Files" heading behind.
        return javascript_tag(<<~JS) if attachments.empty?
          (function (script) {
            var heading = script.previousElementSibling;
            var rule = heading && heading.previousElementSibling;
            if (heading && heading.tagName === 'P') heading.remove();
            if (rule && rule.tagName === 'HR') rule.remove();
          })(document.currentScript);
        JS

        options = {
          :editable => container.attachments_editable?,
          :deletable => container.attachments_deletable?,
          :author => true
        }.merge(options)
        render :partial => 'attachments/links',
          :locals => {
            :container => container,
            :attachments => attachments,
            :options => options,
            :thumbnails => (options[:thumbnails] && Setting.thumbnails_enabled?)
          }
      end
    end
  end
end

Journal.prepend(RedmineEasyNotes::PrivateAttachments::JournalPatch)
Attachment.prepend(RedmineEasyNotes::PrivateAttachments::AttachmentPatch)
AttachmentsHelper.prepend(RedmineEasyNotes::PrivateAttachments::AttachmentsHelperPatch)
