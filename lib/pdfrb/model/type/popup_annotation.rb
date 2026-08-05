# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Popup annotation (s12.5.6.14). Displays text/markup in a pop-up window.
      class PopupAnnotation < Annotation
        def parent; self[:Parent]; end
        def open?; !!value[:Open]; end

        def markup_annotation
          ref = parent
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
