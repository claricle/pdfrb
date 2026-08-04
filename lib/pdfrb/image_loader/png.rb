# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    module PNG
      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        image = document.add(
          {
            Type: :XObject,
            Subtype: :Image,
            Width: info[:width],
            Height: info[:height],
            ColorSpace: info[:color_space],
            BitsPerComponent: info[:bits],
            Filter: :FlateDecode,
            DecodeParms: { Predictor: 15, Columns: info[:width] },
            Length: 0,
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = ""
        image
      end

      def parse_header(data)
        return {} unless data.is_a?(String) && data.bytesize >= 24
        return {} unless data.start_with?("\x89PNG\r\n\x1A\n".b)
        return {} unless data.bytes[12, 4].pack("C*") == "IHDR"

        off = 16
        {
          width: read_u32(data, off),
          height: read_u32(data, off + 4),
          bits: data.getbyte(off + 8),
          color_type: data.getbyte(off + 9),
          color_space: case data.getbyte(off + 9)
                       when 0, 4 then :DeviceGray
                       when 2, 6 then :DeviceRGB
                       when 3 then :Indexed
                       else :DeviceRGB
                       end,
        }
      end

      def read_u32(data, off)
        (data.getbyte(off) << 24) | (data.getbyte(off + 1) << 16) | (data.getbyte(off + 2) << 8) | data.getbyte(off + 3)
      end
    end
  end
end
