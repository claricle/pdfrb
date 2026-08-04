# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    module JPEG
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
            Filter: :DCTDecode,
            Length: data.bytesize,
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = data
        image
      end

      def parse_header(data)
        return {} unless data && data.is_a?(String) && data.bytesize >= 6
        return {} unless data.getbyte(0) == 0xFF && data.getbyte(1) == 0xD8

        i = 2
        while i < data.bytesize - 1
          break unless data.getbyte(i) == 0xFF

          marker = data.getbyte(i + 1)
          i += 2

          next if marker >= 0xD0 && marker <= 0xD9
          next if marker == 0x01

          break if i + 1 >= data.bytesize
          seg_len = (data.getbyte(i) << 8) | data.getbyte(i + 1)

          if marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC
            return parse_sof(data, i)
          end

          i += seg_len
        end
        {}
      end

      def parse_sof(data, offset)
        {
          bits: data.getbyte(offset + 2),
          height: (data.getbyte(offset + 3) << 8) | data.getbyte(offset + 4),
          width: (data.getbyte(offset + 5) << 8) | data.getbyte(offset + 6),
          color_space: case data.getbyte(offset + 7)
                       when 1 then :DeviceGray
                       when 3 then :DeviceRGB
                       when 4 then :DeviceCMYK
                       else :DeviceRGB
                       end,
        }
      end
    end
  end
end
