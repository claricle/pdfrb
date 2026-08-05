# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CalGray color space dictionary (s8.6.3.2). Single-component
      # calibrated grayscale: [/CalGray <dict>].
      class CalGray < Pdfrb::Model::Cos::Dictionary
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def gamma; self[:Gamma] || 1.0; end

        def components; 1; end
      end

      # CalRGB color space dictionary (s8.6.3.3). Calibrated RGB:
      # [/CalRGB <dict>].
      class CalRGB < Pdfrb::Model::Cos::Dictionary
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def gamma; self[:Gamma]; end
        def matrix; self[:Matrix]; end

        def components; 3; end

        def has_matrix?
          !!matrix
        end
      end

      # Lab color space dictionary (s8.6.3.4). CIE L*a*b*:
      # [/Lab <dict>].
      class Lab < Pdfrb::Model::Cos::Dictionary
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def range; self[:Range]; end

        def components; 3; end

        # /Range is [a_min a_max b_min b_max]; defaults per spec are
        # [-100 100 -100 100].
        def a_range
          range ? [range[0], range[1]] : [-100, 100]
        end

        def b_range
          range ? [range[2], range[3]] : [-100, 100]
        end
      end

      # Indexed color space array wrapper. The /Indexed color space is
      # [/Indexed base hival lookup]; the lookup table is the stream payload
      # or a string.
      class Indexed < Pdfrb::Model::Cos::Stream
        def base_color_space; self[:Base]; end
        def hival; self[:Hival]; end
        def lookup; self[:Lookup]; end

        def components
          return nil unless base_color_space

          case base_color_space.to_sym
          when :DeviceGray, :CalGray then 1
          when :DeviceRGB, :CalRGB then 3
          when :DeviceCMYK then 4
          end
        rescue StandardError
          nil
        end

        def palette_entries
          (hival || -1) + 1
        end
      end
    end
  end
end
