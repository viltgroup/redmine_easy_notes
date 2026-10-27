# frozen_string_literal: true

require 'redmine'

require File.expand_path('lib/redmine_easy_notes/settings', __dir__)

Redmine::Plugin.register :redmine_easy_notes do
  name 'Redmine Easy Notes'
  author 'joaoperfig'
  description 'Adds a one-line "Add note" box under the issue history, so a comment can be ' \
              'left without opening the full issue edit form.'
  version '1.0.0'
  url 'https://github.com/joaoperfig/redmine_easy_notes'
  author_url 'https://github.com/joaoperfig'

  # The markup mirrors Redmine 7's journal header (sprite_icon, flex .journal-header,
  # textarea_tag). Earlier versions are untested -- widen this if you verify one.
  requires_redmine version_or_higher: '7.0.0'

  # Administration -> Plugins -> Configure. Read through
  # RedmineEasyNotes::Settings, which documents each switch.
  settings default: RedmineEasyNotes::Settings::DEFAULTS.dup,
           partial: 'settings/easy_notes_settings'

  # Switchable per project, under Project settings -> Modules. Where it is off,
  # the issue page is left exactly as core renders it: no bar, no stylesheet, no
  # script, and therefore core's own Quote behaviour.
  #
  # A module only appears in that list if at least one permission names it,
  # because AccessControl.available_project_modules is derived from the
  # permission list. So this marker permission exists only to register the
  # module. It is public on purpose: Role#setable_permissions subtracts the
  # public permissions, so it never shows in the role form, no role gains or
  # loses anything, and nobody has to re-tick a box after installing this.
  project_module :easy_notes do
    permission :view_easy_notes, {}, public: true
  end

  # Takes over from redmine_silencer, which registered the same name. Roles keep
  # their permissions as a list of names, and that list survives a plugin being
  # removed, so every role that granted it under the silencer grants it again
  # here with nothing to re-tick. Do not install both: the role form would list
  # it twice and the edit form would get two checkboxes.
  #
  # Deliberately outside the module, as it was under the silencer: the issue
  # edit form's checkbox works in every project, and only the quick bar's toggle
  # needs Easy notes switched on.
  #
  # Registered even while the feature is switched off in the plugin settings,
  # since permissions are fixed at boot and the setting is not. Switched off,
  # the permission grants nothing: no checkbox renders and the hook ignores
  # the parameter.
  permission :suppress_mail_notifications, {}
end

require File.expand_path('lib/redmine_easy_notes/hooks', __dir__)
require File.expand_path('lib/redmine_easy_notes/private_attachments', __dir__)
