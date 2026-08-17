# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # JavaScript action (s12.6.4.16). Execute JavaScript code.
      class ActionJavaScript < Action
        arlington_object "ActionECMAScript"
        register_subtype :JavaScript

        def script; self[:JS]; end

        def has_script?
          !!script && (!script.is_a?(String) || !script.empty?)
        end
      end
    end
  end
end
