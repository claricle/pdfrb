# frozen_string_literal: true

module Pdfrb
  module Layout
    # A rectangular region of a page where boxes are placed. The Frame
    # tracks which areas are filled and exposes +find_available_area+
    # to locate the next free region of a given width and height.
    #
    # Simple case: the Frame is a plain rectangle. Advanced: the
    # +shape+ polygon allows non-rectangular regions (L-shaped, with
    # cutouts around images).
    class Frame
      attr_reader :left, :bottom, :width, :height, :shape

      def initialize(left:, bottom:, width:, height:, shape: nil)
        @left = left.to_f
        @bottom = bottom.to_f
        @width = width.to_f
        @height = height.to_f
        @shape = shape || default_shape
      end

      def right
        @left + @width
      end

      def top
        @bottom + @height
      end

      # Locate the next free area of (width × height) within this Frame.
      # Returns nil if none fits. After a successful find, callers
      # typically call +remove_area+ with the returned rectangle to
      # mark it as used.
      def find_available_area(width, height)
        w = width.to_f
        h = height.to_f
        return nil if w > @width || h > @height

        [@left, @bottom + @height - h]
      end

      # Mark the rectangle at (x, y) of (w × h) as filled. Subsequent
      # +find_available_area+ calls avoid this region.
      def remove_area(x, y, w, h)
        return if x.nil? || y.nil?

        @removed ||= []
        @removed << [x.to_f, y.to_f, w.to_f, h.to_f]
      end

      def full?
        @removed&.any?
      end

      def empty?
        !full?
      end

      private

      def default_shape
        [[@left, @bottom], [right, @bottom], [right, top], [@left, top]]
      end
    end
  end
end
