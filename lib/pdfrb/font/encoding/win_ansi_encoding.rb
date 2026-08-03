# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      # WinAnsiEncoding (Windows Code Page 1252, Appendix D.1).
      module WinAnsiEncoding
        TABLE = (0..255).each_with_object(Array.new(256, nil)) do |i, arr|
          arr[i] = i if i < 0x80
        end
        # High-byte mappings (subset — full table is in Windows-1252 spec).
        { 0x80 => 0x20AC, 0x82 => 0x201A, 0x83 => 0x0192, 0x84 => 0x201E,
          0x85 => 0x2026, 0x86 => 0x2020, 0x87 => 0x2021, 0x88 => 0x02C6,
          0x89 => 0x2030, 0x8A => 0x0160, 0x8B => 0x2039, 0x8C => 0x0152,
          0x8E => 0x017D, 0x91 => 0x2018, 0x92 => 0x2019, 0x93 => 0x201C,
          0x94 => 0x201D, 0x95 => 0x2022, 0x96 => 0x2013, 0x97 => 0x2014,
          0x98 => 0x02DC, 0x99 => 0x2122, 0x9A => 0x0161, 0x9B => 0x203A,
          0x9C => 0x0153, 0x9E => 0x017E, 0x9F => 0x0178
        }.each { |b, cp| TABLE[b] = cp }
        (0xA0..0xFF).each { |b| TABLE[b] = b }
        TABLE.freeze

        class << self
          def encode(text)
            Pdfrb::Font::Encoding.encode(:WinAnsiEncoding, text)
          end

          def decode(bytes)
            Pdfrb::Font::Encoding.decode(:WinAnsiEncoding, bytes)
          end

          def encodable?(codepoint)
            return true if codepoint < 0x80

            reverse = Pdfrb::Font::Encoding.reverse_table_for(:WinAnsiEncoding)
            !reverse[codepoint].nil?
          end
        end
      end
    end
  end
end
