# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Square / rectangle annotation (s12.5.6.8).
      class SquareAnnotation < MarkupAnnotation
        arlington_object "AnnotSquare"
        def border_effect; self[:BE]; end
        def interior_color; self[:IC]; end
        def border_style; self[:BS]; end
        def border; self[:Border]; end
        def rd; self[:RD]; end

        def has_border_effect?
          !!border_effect
        end

        def dashed?
          bs && bs[:D]
        end
      end
    end
  end
end
