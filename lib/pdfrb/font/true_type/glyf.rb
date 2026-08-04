# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Glyf
        attr_reader :data, :loca

        def initialize(data, loca = nil)
          @data = data
          @loca = loca
        end

        def glyph_data(glyph_id)
          return nil unless @data && @loca
          return nil if glyph_id >= @loca.offsets.length - 1

          offset = @loca.glyph_offset(glyph_id)
          length = @loca.glyph_length(glyph_id)
          return nil if offset.nil? || length.zero?

          @data.byteslice(offset, length)
        end

        def glyph_header(glyph_id)
          g = glyph_data(glyph_id)
          return nil unless g && g.bytesize >= 10

          {
            number_of_contours: s16(g, 0),
            x_min: s16(g, 2),
            y_min: s16(g, 4),
            x_max: s16(g, 6),
            y_max: s16(g, 8),
          }
        end

        def composite?(glyph_id)
          h = glyph_header(glyph_id)
          h && h[:number_of_contours].negative?
        end

        def empty?(glyph_id)
          length = @loca&.glyph_length(glyph_id) || 0
          length.zero?
        end

        def component_glyphs(glyph_id)
          return [] unless composite?(glyph_id)

          g = glyph_data(glyph_id)
          return [] unless g

          components = []
          offset = 10
          loop do
            break if offset + 4 > g.bytesize

            flags = u16(g, offset)
            glyph_index = u16(g, offset + 2)
            components << glyph_index
            offset += 4

            offset += 4 if flags & 0x0001 != 0
            offset += 2 if flags & 0x0002 != 0
            break if flags.nobits?(0x0020)
          end
          components
        end

        private

        def u16(d, o); (d.getbyte(o) << 8) | d.getbyte(o + 1); end

        def s16(d, o)
          v = u16(d, o)
          v >= 32768 ? v - 65536 : v
        end
      end
    end
  end
end
