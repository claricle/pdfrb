# frozen_string_literal: true

module Pdfrb
  module Filter
    # ASCIIHexDecode (s7.4.2). Hex string -> bytes. EOD marker `>`.
    class ASCIIHexDecode
      include Base

      register_as "ASCIIHexDecode"

      HEX = (0..9).each_with_object({}) { |d, h| h[d.to_s] = d }
                 .merge(("a".."f").each_with_index.with_object({}) { |(c, i), h| h[c] = 10 + i })
                 .merge(("A".."F").each_with_index.with_object({}) { |(c, i), h| h[c] = 10 + i }).freeze
      private_constant :HEX

      class << self
        def decoder(bytes, _parms, _document)
          nibbles = +""
          bytes.each_byte do |b|
            ch = b.chr
            break if ch == ">"

            nibbles << ch if HEX.key?(ch)
          end
          nibbles << "0" if nibbles.length.odd?

          [nibbles].pack("H*").force_encoding(Encoding::BINARY)
        end

        def encoder(bytes, _parms, _document)
          hex = bytes.unpack1("H*")
          "#{hex}>".force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
