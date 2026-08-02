# frozen_string_literal: true

require "zlib"

module Pdfrb
  module Filter
    # FlateDecode (s7.4.8). zlib + optional PNG predictor (s7.4.8.4).
    class FlateDecode
      include Base

      register_as "FlateDecode"

      class << self
        def decoder(bytes, parms, _document)
          decoded = zlib_inflate(bytes)
          return decoded unless parms && parms.is_a?(::Hash)

          predictor = parms[:Predictor] || 1
          return decoded if predictor == 1

          apply_png_predictor_decode(
            decoded,
            predictor: predictor,
            columns: parms[:Columns] || 1,
            colors: parms[:Colors] || 1,
            bits_per_component: parms[:BitsPerComponent] || 8
          )
        end

        def encoder(bytes, parms, _document)
          zlib_deflate(bytes)
        end

        private

        def zlib_inflate(bytes)
          Zlib::Inflate.inflate(bytes)
        rescue Zlib::Error => e
          raise Pdfrb::FilterError.new("FlateDecode inflate failed: #{e.message}",
                                       filter_name: "FlateDecode")
        end

        def zlib_deflate(bytes)
          Zlib::Deflate.deflate(bytes)
        rescue Zlib::Error => e
          raise Pdfrb::FilterError.new("FlateDecode deflate failed: #{e.message}",
                                       filter_name: "FlateDecode")
        end

        # PNG unfilter (s7.4.8.4 / RFC 2083 6.6).
        # predictor: 10..15 = PNG predictors; we implement the None/Sub/Up/
        # Average/Paeth (filter type byte at start of each row).
        def apply_png_predictor_decode(bytes, predictor:, columns:, colors:, bits_per_component:)
          return bytes unless (10..15).cover?(predictor)

          row_len = columns * colors * (bits_per_component / 8)
          row_len += 1 # leading filter-type byte per row
          rows = bytes.each_byte.each_slice(row_len).to_a
          prev_row = nil
          bpp = (colors * (bits_per_component / 8)) || 1
          bpp = 1 if bpp.zero?

          out = +""
          rows.each do |row|
            filter_type = row[0]
            data = row[1..]
            unfiltered = unfilter_row(filter_type, data, prev_row, bpp)
            out << unfiltered.pack("C*")
            prev_row = unfiltered
          end
          out.force_encoding(Encoding::BINARY)
        end

        def unfilter_row(filter_type, data, prev_row, bpp)
          case filter_type
          when 0 then data
          when 1 then png_sub(data, bpp)
          when 2 then png_up(data, prev_row)
          when 3 then png_average(data, prev_row, bpp)
          when 4 then png_paeth(data, prev_row, bpp)
          else data
          end
        end

        def png_sub(data, bpp)
          bytes = data.dup
          bpp.upto(bytes.length - 1).each do |i|
            bytes[i] = (bytes[i] + bytes[i - bpp]) & 0xFF
          end
          bytes
        end

        def png_up(data, prev_row)
          return data unless prev_row

          bytes = data.dup
          (0...bytes.length).each do |i|
            bytes[i] = (bytes[i] + (prev_row[i] || 0)) & 0xFF
          end
          bytes
        end

        def png_average(data, prev_row, bpp)
          bytes = data.dup
          (0...bytes.length).each do |i|
            left = bytes[i - bpp] || 0
            up = prev_row ? (prev_row[i] || 0) : 0
            bytes[i] = (bytes[i] + ((left + up) / 2)) & 0xFF
          end
          bytes
        end

        def png_paeth(data, prev_row, bpp)
          bytes = data.dup
          (0...bytes.length).each do |i|
            left = bytes[i - bpp] || 0
            up = prev_row ? (prev_row[i] || 0) : 0
            up_left = prev_row ? (prev_row[i - bpp] || 0) : 0
            bytes[i] = (bytes[i] + paeth(left, up, up_left)) & 0xFF
          end
          bytes
        end

        def paeth(a, b, c)
          p = a + b - c
          pa = (p - a).abs
          pb = (p - b).abs
          pc = (p - c).abs
          return a if pa <= pb && pa <= pc
          return b if pb <= pc

          c
        end
      end
    end
  end
end
