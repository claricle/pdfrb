# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      class Kern
        attr_reader :pairs

        def initialize(data)
          @pairs = {}
          return unless data && data.bytesize >= 4

          version = u16(data, 0)
          n_tables = u16(data, 2)

          offset = 4
          n_tables.times do
            break if offset + 6 > data.bytesize

            sub_version = u16(data, offset)
            sub_length = u16(data, offset + 2)
            coverage = u16(data, offset + 4)

            if version == 0 && coverage & 0x0001 != 0
              n_pairs = u16(data, offset + 6)
              pair_offset = offset + 14

              n_pairs.times do |p|
                break if pair_offset + 6 > data.bytesize

                left = u16(data, pair_offset)
                right = u16(data, pair_offset + 2)
                value = s16(data, pair_offset + 4)
                @pairs[[left, right]] = value
                pair_offset += 6
              end
            end

            offset += sub_length
          end
        end

        def kerning(left_glyph, right_glyph)
          @pairs[[left_glyph, right_glyph]] || 0
        end

        private

        def u16(d, o); (d.getbyte(o) << 8) | d.getbyte(o + 1); end
        def s16(d, o); v = u16(d, o); v >= 32768 ? v - 65536 : v; end
      end
    end
  end
end
