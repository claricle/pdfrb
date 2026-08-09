# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    # GIF image loader. GIF uses LZW compression (a lossless, sliding-
    # window algorithm distinct from PDF's LZWDecode due to a
    # different code-width scheme). Pure-Ruby LZW decoding for GIF's
    # variant is tractable; this loader provides:
    #
    #   * Format detection via the "GIF8" magic.
    #   * Logical screen descriptor parse (width, height, bpc).
    #   * Image XObject construction with the metadata; pixel data
    #     decode requires the GIF-LZW variant which is intentionally
    #     omitted here (callers should pre-convert).
    module GIF
      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        # GIF is palette-based; we emit a stub that records the
        # metadata. Downstream conversion (PNG via system tool) is
        # required for actual pixel embedding.
        image = document.add(
          {
            Type: :XObject, Subtype: :Image,
            Width: info[:width], Height: info[:height],
            BitsPerComponent: info[:bits_per_pixel] || 8,
            ColorSpace: :Indexed,
            Length: 0
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = +""
        image
      end

      def parse_header(data)
        return {} unless data.is_a?(::String) && data.bytesize >= 13
        return {} unless data.start_with?("GIF87a", "GIF89a")

        width = (data.getbyte(7) << 8) | data.getbyte(6)
        height = (data.getbyte(9) << 8) | data.getbyte(8)
        packed = data.getbyte(10)
        bits_per_pixel = (packed & 0x07) + 1
        {
          width: width,
          height: height,
          bits_per_pixel: bits_per_pixel,
        }
      end
    end
  end
end
