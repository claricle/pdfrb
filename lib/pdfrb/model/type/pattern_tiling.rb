# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 1 tiling pattern (s8.7.3). Repeats a graphical cell.
      class PatternTiling < Pattern
        arlington_object "PatternType1"
        def paint_type; self[:PaintType]; end
        def tiling_type; self[:TilingType]; end
        def bbox; self[:BBox]; end
        def x_step; self[:XStep]; end
        def y_step; self[:YStep]; end
        def resources; self[:Resources]; end
        def matrix; self[:Matrix]; end

        def colored?; paint_type == 1; end
        def uncolored?; paint_type == 2; end

        def constant_spacing?; tiling_type == 1; end
        def no_distortion?; tiling_type == 2; end
        def constant_spacing_no_distortion?; tiling_type == 3; end
      end
    end
  end
end
