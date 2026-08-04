# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Maxp
        attr_reader :version, :num_glyphs, :max_points, :max_contours,
                    :max_composite_points, :max_composite_contours,
                    :max_zones, :max_twilight_points, :max_storage,
                    :max_function_defs, :max_instruction_defs,
                    :max_stack_elements, :max_size_of_instructions,
                    :max_component_elements, :max_component_depth

        def initialize(data)
          return unless data && data.bytesize >= 6

          @version = data.bytes[0, 4].pack("C*").unpack1("N")
          @num_glyphs = u16(data, 4)
          return unless @version == 0x00010000 && data.bytesize >= 32

          @max_points = u16(data, 6)
          @max_contours = u16(data, 8)
          @max_composite_points = u16(data, 10)
          @max_composite_contours = u16(data, 12)
          @max_zones = u16(data, 14)
          @max_twilight_points = u16(data, 16)
          @max_storage = u16(data, 18)
          @max_function_defs = u16(data, 20)
          @max_instruction_defs = u16(data, 22)
          @max_stack_elements = u16(data, 24)
          @max_size_of_instructions = u16(data, 26)
          @max_component_elements = u16(data, 28)
          @max_component_depth = u16(data, 30)
        end

        private

        def u16(data, off)
          (data.getbyte(off) << 8) | data.getbyte(off + 1)
        end
      end
    end
  end
end
