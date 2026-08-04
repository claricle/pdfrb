# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Loca
        attr_reader :offsets

        def initialize(data, long_format: false, num_glyphs: 0)
          @offsets = []
          return unless data

          count = num_glyphs + 1
          count.times do |i|
            @offsets << if long_format
                          u32(data, i * 4)
                        else
                          (u16(data, i * 2) * 2)
                        end
          end
        end

        def glyph_offset(index)
          return nil if index.nil? || index >= @offsets.length

          @offsets[index]
        end

        def glyph_length(index)
          return 0 if index.nil? || index + 1 >= @offsets.length

          @offsets[index + 1] - @offsets[index]
        end

        private

        def u16(data, off); (data.getbyte(off) << 8) | data.getbyte(off + 1); end
        def u32(data, off); (data.getbyte(off) << 24) | (data.getbyte(off + 1) << 16) | (data.getbyte(off + 2) << 8) | data.getbyte(off + 3); end
      end
    end
  end
end
