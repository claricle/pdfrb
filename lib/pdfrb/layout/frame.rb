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
    #
    # Area tracking: +remove_area+ marks a rectangle as used. The
    # Frame maintains a +cursor_y+ that tracks the lowest free
    # vertical position. +find_available_area+ returns the next
    # position at or above the cursor where the requested
    # (width × height) fits without overlapping any removed area.
    class Frame
      attr_reader :left, :bottom, :width, :height, :shape, :cursor_y

      def initialize(left:, bottom:, width:, height:, shape: nil)
        @left = left.to_f
        @bottom = bottom.to_f
        @width = width.to_f
        @height = height.to_f
        @shape = shape || default_shape
        @cursor_y = top
        @removed_areas = []
      end

      def right
        @left + @width
      end

      def top
        @bottom + @height
      end

      # Locate the next free area of (width × height) within this
      # Frame. Scans from the cursor_y downward, checking each
      # candidate y against the removed-areas list. Returns
      # [x, y, w, h] or nil if nothing fits.
      def find_available_area(width, height)
        w = width.to_f
        h = height.to_f
        return nil if w > @width || h > @height
        return nil if h > available_height

        y = @cursor_y - h
        while y >= @bottom
          if area_free?(@left, y, w, h)
            @cursor_y = y
            return [@left, y, w, h]
          end

          y -= 1
        end
        nil
      end

      # Mark the rectangle at (x, y) of (w × h) as filled. Subsequent
      # +find_available_area+ calls avoid this region. Moves the
      # cursor down when the removed area is at the current cursor.
      def remove_area(x, y, w, h)
        return if x.nil? || y.nil?

        @removed_areas << [x.to_f, y.to_f, w.to_f, h.to_f]
        # If the removed area touches the cursor, advance it.
        if (y + h) >= @cursor_y - 1
          @cursor_y = [@cursor_y, y].min
        end
      end

      def full?
        @cursor_y <= @bottom
      end

      def empty?
        @removed_areas.empty?
      end

      def available_height
        @cursor_y - @bottom
      end

      # Reset the cursor and removed-areas list. Used by the
      # Composer when starting a new page with the same Frame.
      def reset!
        @cursor_y = top
        @removed_areas = []
      end

      private

      def area_free?(x, y, w, h)
        @removed_areas.none? { |rx, ry, rw, rh| rectangles_overlap?(x, y, w, h, rx, ry, rw, rh) }
      end

      def rectangles_overlap?(x1, y1, w1, h1, x2, y2, w2, h2)
        x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
      end

      def default_shape
        [[@left, @bottom], [right, @bottom], [right, top], [@left, top]]
      end
    end
  end
end
