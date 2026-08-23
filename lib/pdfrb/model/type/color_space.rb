# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Array-form color spaces (s8.6). A color space is either a
      # single /Name (device spaces) or an array [family *params]
      # whose first element names the family.
      class ColorSpace < Pdfrb::Model::PdfArray
        def family; self[0]; end

        def device?
          size == 1
        end

        def based?
          size > 1
        end
      end

      # [/CalGray <dict>] (s8.6.3.2).
      class CalGrayColorSpace < ColorSpace
        arlington_object "CalGrayColorSpace"

        def cal_gray_dict; self[1]; end

        def gamma
          cal_gray_dict && cal_gray_dict[:Gamma] ? cal_gray_dict[:Gamma] : 1.0
        end
      end

      # [/CalRGB <dict>] (s8.6.3.3).
      class CalRGBColorSpace < ColorSpace
        arlington_object "CalRGBColorSpace"

        def cal_rgb_dict; self[1]; end

        def gamma
          cal_rgb_dict && cal_rgb_dict[:Gamma]
        end
      end

      # [/Lab <dict>] (s8.6.3.4).
      class LabColorSpace < ColorSpace
        arlington_object "LabColorSpace"

        def lab_dict; self[1]; end

        def range
          lab_dict && lab_dict[:Range]
        end
      end

      # [/DeviceGray] etc. (s8.6.4). Single-name device spaces.
      class DeviceGrayColorSpace < ColorSpace
        arlington_object "DeviceGrayColorSpace"

        def components; 1; end
      end

      class DeviceRGBColorSpace < ColorSpace
        arlington_object "DeviceRGBColorSpace"

        def components; 3; end
      end

      class DeviceCMYKColorSpace < ColorSpace
        arlington_object "DeviceCMYKColorSpace"

        def components; 4; end
      end

      # [/ICCBased <stream>] (s8.6.5.5).
      class ICCBasedColorSpaceArray < ColorSpace
        arlington_object "ICCBasedColorSpace"

        def profile_stream; self[1]; end

        def profile_hash?
          profile_stream.is_a?(Pdfrb::Model::Cos::Stream) ||
            profile_stream.is_a?(::Hash)
        end
        private :profile_hash?

        def components
          profile_hash? ? profile_stream[:N] : nil
        end

        def alternate_space
          profile_hash? ? profile_stream[:Alternate] : nil
        end
      end

      # [/Indexed base hival lookup] (s8.6.6.3).
      class IndexedColorSpace < ColorSpace
        arlington_object "IndexedColorSpace"

        def base; self[1]; end
        def hival; self[2]; end
        def lookup; self[3]; end

        def components; 1; end

        def lookup_length
          data = lookup
          return data.bytesize if data.is_a?(::String)

          data.is_a?(Pdfrb::Model::Cos::Stream) ? nil : data&.size
        end
      end

      # [/Separation name alternate tint] (s8.6.6.4).
      class SeparationColorSpace < ColorSpace
        arlington_object "SeparationColorSpace"

        def colorant_name; self[1]; end
        def alternate_space; self[2]; end
        def tint_transform; self[3]; end

        def components; 1; end
      end

      # [/DeviceN names alternate tint attrs] (s8.6.6.5).
      class DeviceNColorSpace < ColorSpace
        arlington_object "DeviceNColorSpace"

        def colorant_names
          names = self[1]
          names.is_a?(Pdfrb::Model::PdfArray) ? names.to_a : names
        end

        def alternate_space; self[2]; end
        def tint_transform; self[3]; end
        def attributes; self[4]; end

        def components
          names = self[1]
          return 1 unless names.is_a?(Pdfrb::Model::PdfArray) || names.is_a?(::Array)

          names.size
        end
      end

      # [/Pattern [base]] (s8.7.3.3). With a base space the pattern
      # is a colored-with-tint (uncolored) pattern family.
      class PatternColorSpace < ColorSpace
        arlington_object "PatternColorSpace"

        def base_space; self[1]; end

        def uncolored?
          !base_space.nil?
        end
      end

      # Black point [X Y Z] inside CalGray/CalRGB/Lab dicts
      # (s8.6.3.1).
      class BlackpointArray < Pdfrb::Model::PdfArray
        arlington_object "BlackpointArray"

        def x; self[0]; end
        def y; self[1]; end
        def z; self[2]; end
      end

      # Resources /ColorSpace dictionary (s7.8.3). Maps resource
      # names to color spaces; also carries the device-space
      # defaults /DefaultGray, /DefaultRGB, /DefaultCMYK.
      class ColorSpaceMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "ColorSpaceMap"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def add(name, color_space)
          value[name.to_sym] = color_space
          name.to_sym
        end

        def default_gray; self[:DefaultGray]; end
        def default_rgb; self[:DefaultRGB]; end
        def default_cmyk; self[:DefaultCMYK]; end

        def each_color_space(&)
          return enum_for(:each_color_space) unless block_given?

          value.each(&)
        end

        def names
          value.keys
        end
      end

      # Colorants dictionary (s8.6.6.5, DeviceN /Colorants). Maps
      # individual colorant names to Separation spaces.
      class ColorantsDict < Pdfrb::Model::Cos::Dictionary
        arlington_object "ColorantsDict"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def each_colorant(&)
          return enum_for(:each_colorant) unless block_given?

          value.each(&)
        end

        def colorant_names
          value.keys
        end
      end

      # Box style dictionary (s7.11.4, BoxColorInfo entries). Guides
      # for the viewer's page-box display.
      class BoxStyle < Pdfrb::Model::Cos::Dictionary
        arlington_object "BoxStyle"

        def color; self[:C]; end
        def width; self[:W] || 1; end
        def style; self[:S]&.to_sym || :S; end
        def dash; self[:D]; end

        def dashed?; style == :D; end
      end
    end
  end
end
