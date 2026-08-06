# frozen_string_literal: true

module Pdfrb
  module Layout
    # Renders an image (PNG or JPEG) into the layout flow. The image
    # is loaded via Pdfrb::ImageLoader and registered with the
    # document's Resources on first draw.
    class ImageBox < Box
      attr_reader :path, :image_data

      def initialize(path:, document:, width: 0, height: 0, **)
        super(width: width, height: height, **)
        @path = path
        @document = document
        @image_data = File.binread(path)
      end

      def fit?(available_width, available_height)
        loader = Pdfrb::ImageLoader.load(@document, @image_data)
        native_w = loader[:Width].to_f
        native_h = loader[:Height].to_f
        target_w = @width.positive? ? @width : native_w
        target_h = @height.positive? ? @height : native_h

        if @width.zero? && @height.zero?
          scale = [available_width / native_w, available_height / native_h].min
          scale = 1.0 if scale > 1
          target_w = native_w * scale
          target_h = native_h * scale
        end

        @width = target_w
        @height = target_h
        @loaded = loader
        @width <= available_width && @height <= available_height
      end

      def draw_content(canvas, x, y)
        name = canvas.document.images.add(@path)
        canvas.draw_image(name, at: [x, y], width: @width, height: @height)
      end
    end
  end
end
