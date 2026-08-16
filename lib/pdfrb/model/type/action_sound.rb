# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Sound action (ISO 32000-2 §12.6.4.11, PDF 1.2, deprecated
      # PDF 2.0). Plays a sound object.
      class ActionSound < Pdfrb::Model::Cos::Dictionary
        arlington_object "ActionSound"

        # /Type — optional, fixed "Action".
        def type
          value[:Type]&.to_sym
        end

        # /S — required, fixed "Sound".
        def action_type
          value[:S]&.to_sym
        end

        # /Sound — required indirect stream with the sound data.
        def sound(document = nil)
          ref = value[:Sound]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /Volume — optional, -1.0 to 1.0 (default 1.0).
        def volume
          value[:Volume] || 1.0
        end

        # /Synchronous — optional, default false.
        def synchronous?
          value[:Synchronous] == true
        end

        # /Repeat — optional, default false.
        def repeat?
          value[:Repeat] == true
        end

        # /Mix — optional, default false. Whether to mix with
        # existing sounds.
        def mix?
          value[:Mix] == true
        end

        # /Next — optional next action(s).
        def next_action(document = nil)
          ref = value[:Next]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end
      end
    end
  end
end
