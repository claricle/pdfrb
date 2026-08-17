# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Launch action (s12.6.4.5). Launch an external application.
      class ActionLaunch < Action
        arlington_object "ActionLaunch"
        register_subtype :Launch

        def file_spec; self[:F]; end
        def new_window?; self[:NewWindow] == true; end
        def win_target; self[:Win]; end
        def mac_target; self[:Mac]; end
        def unix_target; self[:Unix]; end

        def has_platform_target?
          !!win_target || !!mac_target || !!unix_target
        end
      end
    end
  end
end
