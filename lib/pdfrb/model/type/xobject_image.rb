# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Image XObject (s8.9). /Type /XObject, /Subtype /Image,
      # /Width, /Height, /ColorSpace, /BitsPerComponent, etc.
      class XObjectImage < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectImage"

        def subtype; self[:Subtype]; end
        def width; self[:Width]; end
        def height; self[:Height]; end
        def color_space; self[:ColorSpace]; end
        def bits_per_component; self[:BitsPerComponent]; end
        def filter; self[:Filter]; end
        def decode; self[:Decode]; end
        def intent; self[:Intent]; end
        def image_mask?; truthy?(self[:ImageMask]); end
        def mask; self[:Mask]; end
        def smask; self[:SMask]; end
        def smask_in_data; self[:SMaskInData]; end
        def decode_parms; self[:DecodeParms]; end
        def interpolate?; truthy?(self[:Interpolate]); end
        def alternates; self[:Alternates]; end
        def oc; self[:OC]; end
        def name; self[:Name]; end
        def struct_parent; self[:StructParent]; end
        def associated_files; self[:AF]; end

        def components
          cs = color_space
          return 0 unless cs

          case cs.to_sym
          when :DeviceGray, :CalGray, :Indexed then 1
          when :DeviceRGB, :CalRGB, :Lab then 3
          when :DeviceCMYK then 4
          end
        rescue StandardError
          nil
        end

        def masked?
          image_mask? || !!mask
        end

        def has_soft_mask?
          !!smask || smask_in_data.to_i.positive?
        end

        def inline_soft_mask?
          smask_in_data.to_i == 2
        end

        def indexed?
          color_space.is_a?(Array) &&
            color_space.to_ary.first&.to_sym == :Indexed
        end

        def bytes_per_row
          return nil unless width && bits_per_component && components

          ((width * components * bits_per_component) + 7) / 8
        end
      end

      # Image-mask image XObject /ImageMask true (s8.9.6.4):
      # 1-bpp stencil painted with the current fill color.
      class XObjectImageMask < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectImageMask"

        def width; self[:Width]; end
        def height; self[:Height]; end
        def decode; self[:Decode]; end

        # /Decode [0 1] = paint 1-bits; [1 0] = inverted.
        def inverted?; decode && decode[0] == 1; end
      end

      # Soft-mask image XObject (s8.9.6.5): grayscale companion used
      # as a shape/opacity mask via /SMask.
      class XObjectImageSoftMask < Pdfrb::Model::Cos::Stream
        arlington_object "XObjectImageSoftMask"

        def color_space; self[:ColorSpace]; end
        def matte; self[:Matte]; end
      end
    end
  end
end
