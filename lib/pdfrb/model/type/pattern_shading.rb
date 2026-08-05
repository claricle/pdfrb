# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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
