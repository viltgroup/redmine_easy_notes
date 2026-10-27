# frozen_string_literal: true

module RedmineEasyNotes
  # Renders the quick-note bar from inside issues/show.html.erb.
  #
  # This hook, and not :view_layouts_base_content, is deliberate: the partial needs
  # wikitoolbar_for, which calls heads_for_wiki_formatter, which uses
  # content_for :header_tags. The layout yields :header_tags near the top of <head>,
  # so anything contributed from a hook that fires inside the *layout* arrives too
  # late and the jstoolbar assets are silently never loaded. Hooks that fire inside
  # the template still work, because Rails renders the template before the layout.
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, partial: 'hooks/easy_notes'

    # The "Suppress Notifications" checkbox under core's own edit form notes.
    render_on :view_issues_edit_notes_bottom, partial: 'hooks/easy_notes_suppress_mail'
  end

  # Both the quick bar and core's edit form PATCH issues#update, so this one hook
  # covers both. suppress_mail is a top-level param, not issue[...], because it
  # is not an issue attribute -- and it is the name the silencer used.
  class IssueHooks < Redmine::Hook::Listener
    def controller_issues_edit_before_save(context)
      params = context[:params]
      journal = context[:journal]
      return unless RedmineEasyNotes::Settings.silencer?
      return unless journal && params && params[:suppress_mail] == '1'
      return unless User.current.allowed_to?(:suppress_mail_notifications, journal.project)

      # Journal#notify= is core; Journal#send_notification skips the mail when
      # notify? is false. The journal itself is saved as usual.
      journal.notify = false
    end
  end
end
