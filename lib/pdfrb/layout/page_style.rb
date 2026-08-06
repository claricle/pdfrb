# frozen_string_literal: true

module Pdfrb
  module Layout
    # A named page template. A PageStyle knows:
    # - page dimensions (size + orientation)
    # - margin
    # - the next page style (chains)
    # - a block that draws page chrome (header/footer) each time a
    #   new page with this style is created.
    class PageStyle
      attr_reader :name, :page_size, :orientation, :margin, :next_style, :block

      PAGE_SIZES = {
        A4: [595.28, 841.89],
        A3: [841.89, 1190.55],
        A5: [419.53, 595.28],
        Letter: [612.0, 792.0],
        Legal: [612.0, 1008.0],
        Tabloid: [792.0, 1224.0],
      }.freeze

      def initialize(name:, page_size: :A4, orientation: :portrait,
                     margin: 36, next_style: nil, &block)
        @name = name
        @page_size = page_size
        @orientation = orientation
        @margin = margin
        @next_style = next_style || name
        @block = block
      end

      def dimensions
        base = PAGE_SIZES[@page_size] || [612.0, 792.0]
        if @orientation == :landscape
          [base[1], base[0]]
        else
          base
        end
      end

      def width
        dimensions[0]
      end

      def height
        dimensions[1]
      end

      def frame
        m = @margin.is_a?(Array) ? @margin : [@margin] * 4
        Frame.new(
          left: m[3],
          bottom: m[2],
          width: width - m[1] - m[3],
          height: height - m[0] - m[2]
        )
      end

      def draw_chrome(canvas)
        @block&.call(canvas)
      end
    end
  end
end
