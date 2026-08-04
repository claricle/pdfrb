# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    module JPEG
      module_function

      def load(document, path_or_io)
        data = read_data(path_or_io)
        info = parse_jpeg_header(data)

        stream = document.add(
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
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = data
        stream
      end

      def parse_jpeg_header(data)
        return {} unless data && data.bytesize >= 4

        i = 0
        info = { bits: 8 }

        while i < data.bytesize - 1
          marker = (data.getbyte(i) << 8) | data.getbyte(i + 1)

          case marker
          when 0xFFD8
            i += 2
          when 0xFFC0..0xFFCF
            break unless i + 9 < data.bytesize
            info[:bits] = data.getbyte(i + 4)
            info[:height] = (data.getbyte(i + 5) << 8) | data.getbyte(i + 6)
            info[:width] = (data.getbyte(i + 7) << 8) | data.getbyte(i + 8)
            components = data.getbyte(i + 9)
            info[:color_space] = case components
                                 when 1 then :DeviceGray
                                 when 3 then :DeviceRGB
                                 when 4 then :DeviceCMYK
                                 else :DeviceRGB
                                 end
            break
          else
            i += 2
            seg_len = (data.getbyte(i) << 8) | data.getbyte(i + 1) if i + 1 < data.bytesize
            i += seg_len || 2
          end
        end

        info
      end

      def read_data(path_or_io)
        case path_or_io
        when String then File.binread(path_or_io)
        when IO, StringIO then path_or_io.read
        else path_or_io.to_s
        end
      end
    end
  end
end
