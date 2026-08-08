# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    module PNG
      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        dict = {
          Type: :XObject,
          Subtype: :Image,
          Width: info[:width],
          Height: info[:height],
          ColorSpace: info[:color_space],
          BitsPerComponent: info[:bits],
          Filter: :FlateDecode,
          DecodeParms: { Predictor: 15, Columns: info[:width] },
          Length: 0,
        }
        mask = color_key_mask(info)
        dict[:Mask] = mask if mask

        image = document.add(dict, type: Pdfrb::Model::Type::XObjectImage)
        image.stream = ""
        image
      end

      def parse_header(data)
        return {} unless data.is_a?(::String) && data.bytesize >= 24
        return {} unless data.start_with?("\x89PNG\r\n\x1A\n".b)
        return {} unless data.bytes[12, 4].pack("C*") == "IHDR"

        off = 16
        color_type = data.getbyte(off + 9)
        result = {
          width: read_u32(data, off),
          height: read_u32(data, off + 4),
          bits: data.getbyte(off + 8),
          color_type: color_type,
          color_space: case color_type
                       when 0, 4 then :DeviceGray
                       when 2, 6 then :DeviceRGB
                       when 3 then :Indexed
                       else :DeviceRGB
                       end,
        }
        result[:trns] = read_trns_chunk(data, color_type)
        result
      end

      # Walk the PNG chunks looking for tRNS. Returns the raw tRNS
      # payload bytes, or nil if absent. Stops at IDAT to avoid
      # scanning the whole file.
      def read_trns_chunk(data, color_type)
        offset = 8 # skip PNG signature
        while offset + 8 <= data.bytesize
          length = read_u32(data, offset)
          chunk_type = data.byteslice(offset + 4, 4)
          offset += 8
          case chunk_type
          when "IHDR" # already parsed; skip
            offset += length + 4
          when "tRNS"
            return data.byteslice(offset, length)
          when "IDAT", "IEND"
            return nil
          else
            offset += length + 4
          end
        end
        nil
      end

      # Build a PDF /Mask color-key array from the tRNS chunk. Each
      # entry is [min, max] per channel. Returns nil if tRNS is
      # absent or for indexed color (which uses /SMask instead).
      def color_key_mask(info)
        trns = info[:trns]
        return nil unless trns
        return nil if info[:color_type] == 3 # palette uses /SMask

        case info[:color_type]
        when 0 # grayscale: 1 two-byte value
          v = read_u16(trns, 0)
          [v, v]
        when 2, 6 # RGB: 3 two-byte values
          r = read_u16(trns, 0)
          g = read_u16(trns, 2)
          b = read_u16(trns, 4)
          [r, r, g, g, b, b]
        when 4 # grayscale+alpha: same as grayscale
          v = read_u16(trns, 0)
          [v, v]
        end
      end

      def read_u16(data, off)
        return 0 unless data && data.bytesize >= off + 2

        (data.getbyte(off) << 8) | data.getbyte(off + 1)
      end

      def read_u32(data, off)
        (data.getbyte(off) << 24) | (data.getbyte(off + 1) << 16) |
          (data.getbyte(off + 2) << 8) | data.getbyte(off + 3)
      end
    end
  end
end
