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
    end
  end
end
