# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Sound action (s12.6.4.6). Plays a Sound stream.
      class ActionSoundAction < Action
        register_subtype :Sound

        def sound; self[:Sound]; end
        def volume; self[:Volume]; end
        def mix?; truthy?(self[:Mix]); end

        def resolved_sound
          ref = sound
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
