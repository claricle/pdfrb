# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # Helpers for PDF Name (s7.3.5): a Symbol on the Ruby side, a
      # `/...` token on the wire. Non-printable or delimiter bytes are
      # `#xx`-escaped; we always emit `#` escapes for the delimiter set
      # even when printable, to match HexaPDF behaviour.
      module NameEncoding
        DELIMITERS = "()<>[]{}/%".b
        WHITESPACE = " \t\n\f\r\0".b
        ESCAPE_CHARS = (DELIMITERS + WHITESPACE + "#").b.chars.uniq.freeze

        module_function

        # Symbol -> "/..." String ready for the byte stream.
        def encode(sym)
          raise ArgumentError, "Name must be a Symbol" unless sym.is_a?(Symbol)

          +"/" << sym.to_s.each_char.with_object(+"") do |ch, buf|
            buf << if ESCAPE_CHARS.include?(ch) || ch.bytes.any? { |b| b < 33 || b > 126 }
                     "#%02X" % ch.bytes.first
                   else
                     ch
                   end
          end
        end

        # "/..." or "..." String -> Symbol. `#xx` sequences decoded.
        def decode(str)
          s = str.to_s
          s = s.delete_prefix("/")
          out = +""
          i = 0
          bytes = s.bytes
          while i < bytes.length
            b = bytes[i]
            if b == 35 # #
              hex = bytes[i + 1, 2]
              if hex && hex.length == 2 && hex.all? { |h| hex_byte?(h) }
                hex_str = hex.map(&:chr).join
                out << hex_str.to_i(16).chr
                i += 3
              else
                out << "#"
                i += 1
              end
            else
              out << b.chr
              i += 1
            end
          end
          out.to_sym
        end

        def hex_byte?(b)
          (48..57).cover?(b) || (65..70).cover?(b) || (97..102).cover?(b)
        end
        module_function :hex_byte?
      end
    end
  end
end
