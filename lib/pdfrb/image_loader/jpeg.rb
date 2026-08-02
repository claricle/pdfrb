# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    # JPEG loader. Parses the SOI/SOFn marker stream to extract width,
    # height, bits-per-component, and number of components. The raw
    # JPEG bytes are stored verbatim with /Filter /DCTDecode — no
    # re-encoding.
    module JPEG
      SOI = "\xFF\xD8".b
      SOFN_MARKERS = [
        0xFFC0, 0xFFC1, 0xFFC2, 0xFFC3,
        0xFFC5, 0xFFC6, 0xFFC7,
        0xFFC9, 0xFFCA, 0xFFCB,
        0xFFCD, 0xFFCE, 0xFFCF
      ].freeze
      private_constant :SOI, :SOFN_MARKERS

      module_function

      def call(document, bytes, **_opts)
        return nil unless bytes.is_a?(::String) && bytes.start_with?(SOI)

        info = parse_header(bytes)
        image = document.add(
          {
            Type: :XObject,
            Subtype: :Image,
            Width: info[:width],
            Height: info[:height],
            BitsPerComponent: info[:precision],
            ColorSpace: info[:color_space],
            Filter: :DCTDecode
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = bytes.b
        image
      end

      def parse_header(bytes)
        i = 2 # skip SOI marker
        while i + 1 < bytes.bytesize
          marker = bytes.getbyte(i) * 256 + bytes.getbyte(i + 1)
          i += 2
          # Standalone markers (no length): RSTn, SOI, EOI, TEM.
          standalone = (0xFFD0..0xFFD7).include?(marker) ||
                       marker == 0xFF01 || marker == 0xFFD8 || marker == 0xFFD9
          if SOFN_MARKERS.include?(marker)
            return parse_sofn(bytes, i)
          elsif standalone
            next
          else
            length = bytes.getbyte(i) * 256 + bytes.getbyte(i + 1)
            i += length
          end
        end
        raise Pdfrb::Error, "JPEG: no SOFn marker found"
      end
      private_class_method :parse_header

      def parse_sofn(bytes, i)
        # SOFn layout: precision(1), height(2), width(2), components(1)
        _length = bytes.getbyte(i) * 256 + bytes.getbyte(i + 1)
        precision = bytes.getbyte(i + 2)
        height = bytes.getbyte(i + 3) * 256 + bytes.getbyte(i + 4)
        width = bytes.getbyte(i + 5) * 256 + bytes.getbyte(i + 6)
        components = bytes.getbyte(i + 7)
        {
          precision: precision,
          width: width,
          height: height,
          components: components,
          color_space: color_space_for(components)
        }
      end
      private_class_method :parse_sofn

      def color_space_for(n)
        case n
        when 1 then :DeviceGray
        when 3 then :DeviceRGB
        when 4 then :DeviceCMYK
        else raise Pdfrb::Error, "JPEG: unsupported component count #{n}"
        end
      end
      private_class_method :color_space_for
    end
  end
end
