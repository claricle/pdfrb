# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rendition action (s12.6.4.12). Controls multimedia rendition
      # on screen annotations.
      class ActionRendition < Action
        register_subtype :Rendition

        def rendition; self[:R]; end
        def screen_annotation; self[:AN]; end
        def operation; self[:OP]; end
        def javascript; self[:JS]; end

        def play?; operation.zero?; end
        def stop?; operation == 1; end
        def pause?; operation == 2; end
        def resume?; operation == 3; end
        def play_resume?; operation == 4; end

        def has_javascript?
          !!javascript
        end
      end

      # Movie action (s12.6.4.8). Deprecated in PDF 2.0 but still
      # appears in legacy PDFs. Plays/stops a Movie annotation.
      class ActionMovie < Action
        register_subtype :Movie

        def annotation; self[:Annotation]; end
        def title; self[:T]; end
        def operation; self[:Operation]&.to_sym || :Play; end

        def play?; operation == :Play; end
        def stop?; operation == :Stop; end
        def pause?; operation == :Pause; end
        def resume?; operation == :Resume; end
      end

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

      # Set-state action (deprecated in PDF 1.2, replaced by SetOCGState).
      class ActionSetState < Action
        register_subtype :SetState

        def state; self[:State]; end
      end

      # Thread action (s12.6.4.6). Navigate within an article thread.
      class ActionThread < Action
        register_subtype :Thread

        def thread; self[:F]; end
        def destination_bead; self[:D]; end

        def first_bead?
          destination_bead.zero? || destination_bead.nil?
        end

        def last_bead?
          destination_bead == -1
        end
      end

      # GoTo3DView action (s12.6.4.12, PDF 1.6+). Navigate within a 3D stream.
      class ActionGoTo3DView < Action
        register_subtype :GoTo3DView

        def target_view; self[:TA]; end
      end
    end
  end
end
