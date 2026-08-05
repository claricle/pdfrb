# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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
