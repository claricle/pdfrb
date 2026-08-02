# frozen_string_literal: true

module Pdfrb
  module Filter
    # ASCII85Decode (s7.4.3). Adobe's base-85 encoding with EOD `~>`.
    # The `z` shorthand expands to four zero bytes.
    class ASCII85Decode
      include Base

      register_as "ASCII85Decode"

      class << self
        def decoder(bytes, _parms, _document)
          out = +""
          group = []
          bytes.each_byte do |b|
            ch = b.chr
            case ch
            when "z"
              raise bad_byte(b) unless group.empty?

              out << "\x00\x00\x00\x00".b
            when "~"
              # EOD marker. Flush any partial group.
              break
            when " "
            else
              next unless (33..117).cover?(b)

              group << b
              if group.length == 5
                out << decode_group(group)
                group.clear
              end
            end
          end
          unless group.empty?
            n = group.length
            padded = group + [117] * (5 - n)
            decoded = decode_group(padded)
            out << decoded.byteslice(0, n - 1)
          end
          out.force_encoding(Encoding::BINARY)
        end

        def encoder(bytes, _parms, _document)
          out = +""
          bytes.bytes.each_slice(4) do |quad|
            padded = quad + [0] * (4 - quad.length)
            num = padded[0] << 24 | padded[1] << 16 | padded[2] << 8 | padded[3]
            chars = +""
            5.times { chars << (num % 85 + 33).chr; num /= 85 }
            chars.reverse!
            n = quad.length + 1
            out << chars.byteslice(0, n)
          end
          out << "~>"
          out.force_encoding(Encoding::BINARY)
        end

        private

        def decode_group(group)
          num = group.reduce(0) { |acc, b| acc * 85 + (b - 33) }
          [
            (num >> 24) & 0xFF,
            (num >> 16) & 0xFF,
            (num >> 8) & 0xFF,
            num & 0xFF
          ].pack("C4").force_encoding(Encoding::BINARY)
        end

        def bad_byte(b)
          Pdfrb::FilterError.new("ASCII85Decode bad byte #{b}", filter_name: "ASCII85Decode")
        end
      end
    end
  end
end
