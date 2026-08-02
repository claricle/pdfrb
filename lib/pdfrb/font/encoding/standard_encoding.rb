# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      # StandardEncoding (Adobe Standard, Appendix D.4).
      # Maps glyph names to byte positions.
      module StandardEncoding
        GLYPH_NAMES = {
          0x20 => "space", 0x21 => "exclam", 0x22 => "quotedbl",
          0x23 => "numbersign", 0x24 => "dollar", 0x25 => "percent",
          0x26 => "ampersand", 0x27 => "quoteright", 0x28 => "parenleft",
          0x29 => "parenright", 0x2A => "asterisk", 0x2B => "plus",
          0x2C => "comma", 0x2D => "hyphen", 0x2E => "period",
          0x2F => "slash", (0x30..0x39).map { |d| [d, ("0".ord + d - 0x30).chr] } => nil
        }.freeze

        TABLE = (0..255).each_with_object(Array.new(256, nil)) do |i, arr|
          arr[i] = i if i < 0x80
        end.freeze
      end
    end
  end
end
