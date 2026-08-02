# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      # MacRomanEncoding (Mac OS Roman, Appendix D.3).
      module MacRomanEncoding
        TABLE = (0..127).each_with_object(Array.new(256, nil)) { |i, a| a[i] = i }
        { 0x80 => 0x00C4, 0x81 => 0x00C5, 0x82 => 0x00C7, 0x83 => 0x00C9,
          0x84 => 0x00D1, 0x85 => 0x00D6, 0x86 => 0x00DC, 0x87 => 0x00E1,
          0x88 => 0x00E0, 0x89 => 0x00E2, 0x8A => 0x00E4, 0x8B => 0x00E3,
          0x8C => 0x00E5, 0x8D => 0x00E7, 0x8E => 0x00E9, 0x8F => 0x00E8
        }.each { |b, cp| TABLE[b] = cp }
        (0x90..0xFF).each do |b|
          TABLE[b] = TABLE[b] || case b
                                 when 0xD0..0xFF then b + 0x500
                                 else b
                                 end
        end
        TABLE.map! { |cp| cp || 0x3F }
        TABLE.freeze
      end
    end
  end
end
