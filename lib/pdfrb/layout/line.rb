# frozen_string_literal: true

module Pdfrb
  module Layout
    # A single line of text — an ordered list of TextFragment instances
    # sharing a baseline. Knows its total width/height/ascent/descent.
    class Line
      attr_reader :fragments

      def initialize(fragments: [])
        @fragments = fragments
      end

      def width
        @fragments.sum(&:width)
      end

      def height
        return 0 if @fragments.empty?

        max_top = @fragments.map(&:y_max).max
        min_bottom = @fragments.map(&:y_min).min
        max_top - min_bottom
      end

      def ascender
        @fragments.map(&:y_max).max || 0
      end

      def descender
        @fragments.map(&:y_min).min || 0
      end

      def empty?
        @fragments.empty?
      end

      # Draw the line at baseline (x, y) applying the requested alignment
      # within the available width.
      def draw(canvas, x, y, available_width:, alignment: :left)
        offset = if alignment == :center
                   x + ((available_width - width) / 2)
                 elsif alignment == :right
                   x + available_width - width
                 else
                   x
                 end
        @fragments.each do |frag|
          frag.draw(canvas, offset, y)
          offset += frag.width
        end
      end
    end
  end
end
