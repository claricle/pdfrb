# frozen_string_literal: true

module Pdfrb
  module Filter
    # PNG predictor (de)coding shared between FlateDecode and LZWDecode
    # (s7.4.8.4 / RFC 2083 6.6). Extracted as a standalone module so
    # both filters can use it without one calling the other's private
    # methods.
    module PNGPredictor
      module_function

      def decode(bytes, predictor:, columns:, colors:, bits_per_component:)
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
