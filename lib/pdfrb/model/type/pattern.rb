# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Pattern dictionary base (s8.7.2). Patterns tile or shade to fill
      # graphics. Two pattern types: tiling (Type 1) and shading (Type 2).
      class Pattern < Pdfrb::Model::Cos::Dictionary
        def pattern_type; self[:PatternType]; end

        def tiling?; pattern_type == 1; end
        def shading?; pattern_type == 2; end
      end

      # Type 1 tiling pattern (s8.7.3). Repeats a graphical cell.
      class PatternTiling < Pattern
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

      # Type 2 shading pattern (s8.7.4.1). Fills with a Shading dict.
      class PatternShading < Pattern
        def shading; self[:Shading]; end
        def matrix; self[:Matrix]; end
        def ext_g_state; self[:ExtGState]; end

        def has_matrix?
          !!matrix
        end

        def resolved_shading
          ref = shading
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
