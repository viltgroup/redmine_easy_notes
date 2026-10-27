# frozen_string_literal: true

module RedmineEasyNotes
  # Reads the switches on Administration -> Plugins -> Easy notes -> Configure.
  #
  # Core stores the settings form as one hash and returns it whole, falling back
  # to the defaults only when nothing has been saved yet. Falling back key by key
  # here as well means a switch added in a later version starts at its default
  # instead of reading as off on an install that saved the form before it existed.
  module Settings
    # All on, which is how the plugin behaved before these switches existed.
    DEFAULTS = {
      'private_toggle' => '1',
      'silencer' => '1',
      'suppress_toggle' => '1'
    }.freeze

    def self.on?(key)
      stored = Setting.plugin_redmine_easy_notes
      value = stored.is_a?(Hash) && stored.key?(key) ? stored[key] : DEFAULTS[key]
      value.to_s == '1'
    end

    # The public/private icon on the one-line bar. The full editor's checkbox
    # does not depend on it.
    def self.private_toggle?
      on?('private_toggle')
    end

    # The whole suppress-notifications feature: the bar's icon, both checkboxes,
    # and the hook that acts on them.
    def self.silencer?
      on?('silencer')
    end

    # The suppress icon on the one-line bar. Meaningless without the feature.
    def self.suppress_toggle?
      silencer? && on?('suppress_toggle')
    end
  end
end
