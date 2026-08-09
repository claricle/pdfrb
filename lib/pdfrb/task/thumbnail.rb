# frozen_string_literal: true

module Pdfrb
  module Task
    # Generates a low-resolution thumbnail for each page (or a single
    # page) and attaches it via the page-level /Thumb key. PDF
    # viewers use /Thumb to render page previews quickly without
    # parsing the full content stream.
    #
    # The thumbnail is a Form XObject rendered to a small image
    # XObject. Pure-Ruby implementation: renders only the page's text
    # (no image / form XObject content) at the target resolution
    # using the standard 14 AFM metrics when available, otherwise a
    # placeholder rectangle.
    module Thumbnail
      DEFAULT_DPI = 72
      DEFAULT_MAX_WIDTH = 200

      module_function

      # Generate thumbnails for every page in +document+. Returns the
      # count of thumbnails added. Idempotent: existing /Thumb
      # entries are left alone unless +force:+ is true.
      def call(document, dpi: DEFAULT_DPI, max_width: DEFAULT_MAX_WIDTH, force: false)
        count = 0
        document.pages.each do |page|
          next if page.value[:Thumb] && !force

          thumb = build_thumbnail(document, page, dpi: dpi, max_width: max_width)
          next unless thumb

          page.value[:Thumb] = Pdfrb::Model::Reference.new(thumb.oid, thumb.gen)
          count += 1
        end
        count
      end

      # Build a single thumbnail image XObject for +page+ at the
      # given DPI, capped at +max_width+ pixels. Returns the image
      # XObject or nil if the page has no media box.
      def build_thumbnail(document, page, dpi: DEFAULT_DPI, max_width: DEFAULT_MAX_WIDTH)
        media_box = page.value[:MediaBox]
        return nil unless media_box.is_a?(::Array) && media_box.length == 4

        width, height = page_pixel_dimensions(media_box, dpi, max_width)
        return nil unless width.positive? && height.positive?

        # Single-component grayscale image — 1 byte per pixel.
        # White background, black "text" rectangle placeholder. Real
        # text rendering would require running the content processor
        # against a rasteriser; that's a much larger feature.
        pixel_data = render_placeholder(width, height, page)
        compressed = require_zlib.deflate(pixel_data)

        image = document.add(
          {
            Type: :XObject, Subtype: :Image,
            Width: width, Height: height,
            ColorSpace: :DeviceGray,
            BitsPerComponent: 8,
            Filter: :FlateDecode,
            Length: compressed.bytesize
          },
          type: Pdfrb::Model::Cos::Stream
        )
        image.stream = compressed
        image
      end

      # Compute thumbnail pixel dimensions, capped at +max_width+.
      def page_pixel_dimensions(media_box, dpi, max_width)
        _x0, _y0, x1, y1 = media_box
        pt_w = x1.to_f
        pt_h = y1.to_f
        return [0, 0] if pt_w.zero? || pt_h.zero?

        scale = (dpi / 72.0) * (max_width.to_f / pt_w)
        scale = 1.0 if scale > 1.0
        [(pt_w * scale).round, (pt_h * scale).round]
      end

      # Render a 1-bpp-style grayscale placeholder: white background,
      # a black border, and a few black "text line" rectangles
      # representing where text content might appear. Pure visual
      # cue, not a real render.
      def render_placeholder(width, height, _page)
        bytes = Array.new(width * height, 255) # white

        draw_rect(bytes, width, height, 0, 0, width, height, 0) # border (black)
        # Determine text area: roughly 80% of page width, centred
        margin = (width * 0.1).round
        text_top = (height * 0.85).round
        line_height = (height * 0.02).round
        line_height = 1 if line_height.zero?
        line_count = [(height * 0.6 / line_height).floor, 3].max
        line_count.times do |i|
          y = text_top - (i * line_height * 2)
          draw_horizontal_line(bytes, width, height, margin, y,
                               width - margin, 0)
        end
        bytes.pack("C*").b
      end

      def draw_rect(bytes, width, height, x0, y0, x1, y1, value)
        x0.upto([x1 - 1, width - 1].min) do |x|
          set_pixel(bytes, width, height, x, y0, value)
          set_pixel(bytes, width, height, x, y1 - 1, value)
        end
        y0.upto([y1 - 1, height - 1].min) do |y|
          set_pixel(bytes, width, height, x0, y, value)
          set_pixel(bytes, width, height, x1 - 1, y, value)
        end
      end

      def draw_horizontal_line(bytes, width, height, x0, y, x1, value)
        x0.upto([x1 - 1, width - 1].min) do |x|
          set_pixel(bytes, width, height, x, y, value)
        end
      end

      def set_pixel(bytes, width, height, x, y, value)
        return if x.negative? || y.negative? || x >= width || y >= height

        bytes[(y * width) + x] = value
      end

      def require_zlib
        require "zlib"
        ::Zlib
      end
    end
  end
end
