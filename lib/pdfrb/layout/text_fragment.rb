# frozen_string_literal: true

module Pdfrb
  module Layout
    # A single fragment of styled text — one run of consecutive glyphs
    # with the same Style. Pieces are [[glyph_id, x_offset, width], ...]
    # in font units.
    class TextFragment
      attr_reader :pieces, :style, :width, :height, :y_min, :y_max

      def initialize(pieces:, style:, width:, height:, y_min:, y_max:)
        @pieces = pieces
        @style = style
        @width = width
        @height = height
        @y_min = y_min
        @y_max = y_max
      end

      def ascender
        @y_max
      end

      def descender
        -@y_min
      end

      def draw(canvas, x, y)
        canvas.save_graphics_state do
          if @style.fill_color
            canvas.fill_color(@style.fill_color)
          end
          canvas.text(@pieces.map(&:first).pack("U*"), at: [x, y],
                                                       font: font_name_for_canvas, size: @style.font_size)
        end
      end

      private

      def font_name_for_canvas
        @style.font_name || :Helvetica
      end
    end
  end
end
