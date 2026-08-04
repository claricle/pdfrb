# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class SquareCircle < Annotation
        def interior_color; self[:IC]; end
        def border_effect; self[:BE]; end
        def rect_difference; self[:RD]; end
      end
    end
  end
end
