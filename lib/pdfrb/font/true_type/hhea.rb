# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # `hhea` (Horizontal Header) table parser. Exposes ascender,
      # descender, line_gap, number_of_hmetrics (used by `hmtx`).
      #
      # Spec: OpenType "hhea" v1.0 — 36 bytes.
      class Hhea
        attr_reader :ascender, :descender, :line_gap,
                    :number_of_hmetrics, :advance_width_max

        def initialize(data)
          @data = data
          return unless data && data.bytesize >= 36

          @ascender = s16(4)
          @descender = s16(6)
          @line_gap = s16(8)
          @advance_width_max = u16(10)
          @number_of_hmetrics = u16(34)
        end

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
