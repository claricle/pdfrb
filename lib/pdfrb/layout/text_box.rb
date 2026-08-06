# frozen_string_literal: true

module Pdfrb
  module Layout
    # Renders a string of text with word-wrap into a region. Uses
    # TextLayouter internally.
    class TextBox < Box
      attr_reader :text, :lines

      def initialize(text:, **)
        super(**)
        @text = text.to_s
        @lines = []
      end

      def fit?(available_width, available_height)
        layouter = TextLayouter.new(@style)
        @lines = layouter.layout(@text, available_width)
        @width = available_width
        @height = @lines.sum(&:height)
        @height <= available_height
      end

      def draw_content(canvas, x, y)
        offset_y = y - (@lines.first&.ascender || 0)
        @lines.each do |line|
          line.draw(canvas, x, offset_y, available_width: @width,
                                        alignment: @style.text_align || :left)
          offset_y -= line.height
        end
      end

      def empty?
        @text.empty?
      end
    end
  end
end
