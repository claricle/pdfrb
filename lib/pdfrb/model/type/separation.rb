# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Separation color space (s8.6.6.3). A single custom colorant
      # mapped through a tint-transform function. Used for spot colors
      # like PANTONE 185 C.
      class Separation < Pdfrb::Model::Cos::Dictionary
        def alternate_space; self[:AlternateSpace]; end
        def tint_transform; self[:TintTransform]; end
        def colorant_name; self[:Colorant]; end

        def components; 1; end

        def resolved_tint_transform
          ref = tint_transform
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
