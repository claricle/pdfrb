# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # `hmtx` (Horizontal Metrics) table parser. Provides per-glyph
      # advance widths and left-side bearings.
      #
      # Layout: `numberOfHMetrics` records of (u16 advance, u16 lsb),
      # followed by (`numGlyphs - numberOfHMetrics`) u16 lsbs (those
      # glyphs share the last advance width).
      class Hmtx
        attr_reader :advances, :lsbs, :number_of_hmetrics

        def initialize(data, number_of_hmetrics:)
          @data = data || "".b
          @number_of_hmetrics = number_of_hmetrics
          parse
        end

        def advance_width(glyph_id)
          return 0 if @advances.empty?

          if glyph_id < @number_of_hmetrics
            @advances[glyph_id]
          else
            @advances.last
          end
        end

        def lsb(glyph_id)
          @lsbs[glyph_id] || @lsbs.last || 0
        end

        private

        def parse
          @advances = []
          @lsbs = []
          return if @data.bytesize < @number_of_hmetrics * 4

          @number_of_hmetrics.times do |i|
            base = i * 4
            @advances << u16(base)
            @lsbs << s16(base + 2)
          end
        end

        def u16(off); (@data.getbyte(off) * 256) + @data.getbyte(off + 1); end

        def s16(off)
          v = u16(off)
          v >= 0x8000 ? v - 0x10000 : v
        end
      end
    end
  end
end
