# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    module PNG
      module_function

      def load(document, path_or_io)
        data = read_data(path_or_io)
        info = parse_png_header(data)

        stream = document.add(
          {
            Type: :XObject,
            Subtype: :Image,
            Width: info[:width],
            Height: info[:height],
            ColorSpace: info[:color_space],
            BitsPerComponent: info[:bits],
            Filter: :FlateDecode,
            DecodeParms: {
              Predictor: 15,
              Columns: info[:width],
            },
            Length: 0,
          },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = ""
        stream
      end

      def parse_png_header(data)
        return {} unless data && data.bytesize >= 24

        return {} unless data.start_with?("\x89PNG\r\n\x1A\n".b)

        chunk_len = (data.getbyte(8) << 24) | (data.getbyte(9) << 16) | (data.getbyte(10) << 8) | data.getbyte(11)
        return {} unless data.bytes[12, 4].pack("C*") == "IHDR"

        offset = 16
        width = read_u32(data, offset)
        height = read_u32(data, offset + 4)
        bits = data.getbyte(offset + 8)
        color_type = data.getbyte(offset + 9)

        color_space = case color_type
                      when 0, 4 then :DeviceGray
                      when 2, 6 then :DeviceRGB
                      when 3 then :Indexed
                      else :DeviceRGB
                      end

        { width: width, height: height, bits: bits, color_space: color_space, color_type: color_type }
      end

      def read_data(path_or_io)
        case path_or_io
        when String then File.binread(path_or_io)
        when IO, StringIO then path_or_io.read
        else path_or_io.to_s
        end
      end

      def read_u32(data, off)
        (data.getbyte(off) << 24) | (data.getbyte(off + 1) << 16) | (data.getbyte(off + 2) << 8) | data.getbyte(off + 3)
      end
    end
  end
end
