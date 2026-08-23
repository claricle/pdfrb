# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Separation color space (s8.6.6.3). A single custom colorant
      # mapped through a tint-transform function. Used for spot colors
      # like PANTONE 185 C.
      class Separation < Pdfrb::Model::Cos::Dictionary
        arlington_object "Separation"
        def color_space; self[:ColorSpace]; end
        def device_colorant; self[:DeviceColorant]; end
        def key; self[:Key]; end
        def pages; self[:Pages]; end

        def resolved_tint_transform
          ref = tint_transform
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
