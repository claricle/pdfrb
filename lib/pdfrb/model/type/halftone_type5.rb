# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 5 halftone: a dictionary mapping colorant name → HalftoneType1.
      class HalftoneType5 < Halftone
        def halftones; self[:Halftones]; end
        def default; self[:Default]; end

        def colorant_count
          return 0 unless halftones

          obj = if halftones.is_a?(Pdfrb::Model::Reference) && document
                  document.object(halftones)
                else
                  halftones
                end
          obj.respond_to?(:value) ? obj.value.size : obj&.size || 0
        end
      end
    end
  end
end
