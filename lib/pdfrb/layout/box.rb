# frozen_string_literal: true

module Pdfrb
  module Layout
    # Base class for all layout boxes. A Box has a width, height, and
    # content; it knows how to fit itself into a Frame region and how
    # to draw onto a Canvas at a given (x, y) location.
    #
    # Subclasses override +fit+ (compute height for given width) and
    # +draw_content+ (render to canvas).
    class Box
      attr_reader :style, :width, :height

      def initialize(width: 0, height: 0, style: Style.new(:base), **)
        @width = width.to_f
        @height = height.to_f
        @style = style
      end

      # Fit this box into the given available (width, height) region.
      # Returns true if it fits (sets @height); false otherwise.
      # Subclasses override.
      def fit?(_available_width, _available_height)
        true
      end

      # Draw this box at (x, y) on +canvas+. Subclasses override
      # +draw_content+.
      def draw(canvas, x, y)
        draw_background(canvas, x, y)
        draw_content(canvas, x, y)
      end

      def supports_position_flow?
        false
      end

      def empty?
        false
      end

      protected

      def draw_background(canvas, x, y); end

      def draw_content(canvas, x, y); end
    end
  end
end
