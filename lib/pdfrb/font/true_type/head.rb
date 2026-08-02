# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # `head` table parser. Exposes units_per_em, bbox, index_format
      # (loca long vs short), mac_style flags.
      #
      # Spec: OpenType "head" v1.0 — 54 bytes.
      class Head
        attr_reader :units_per_em, :bbox, :index_to_loc_format,
                    :mac_style, :lowest_rec_ppem, :font_direction_hint

        def initialize(data)
          @data = data
          return unless data && data.bytesize >= 54

          @units_per_em = u16(18)
          @bbox = [s16(36), s16(38), s16(40), s16(42)]
          @index_to_loc_format = s16(50)
          @mac_style = u16(44)
          @lowest_rec_ppem = u16(48)
          @font_direction_hint = s16(52)
        end

        def long_loca?; @index_to_loc_format == 1; end
        def short_loca?; @index_to_loc_format.zero?; end

        def bold?; (@mac_style || 0) & 0x01 != 0; end
        def italic?; (@mac_style || 0) & 0x02 != 0; end

        private

        def u16(off); (@data.getbyte(off) * 256) + @data.getbyte(off + 1); end

        def s16(off)
          v = u16(off)
          v >= 0x8000 ? v - 0x10000 : v
        end
      end
    end
  end
end
