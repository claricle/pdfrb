# frozen_string_literal: true

module Pdfrb
  module Layout
    # Polygon-aware Frame: extends Frame to compute available area
    # against an arbitrary polygon shape, not just a rectangle.
    # Useful for L-shaped text regions, text-around-image, and
    # irregular page layouts.
    #
    # The default Frame.find_available_area always returns the
    # top-left rectangle; this subclass finds the largest inscribed
    # rectangle of (width × height) inside the polygon, scanning
    # row-by-row to find the leftmost x where the requested box fits
    # at the requested height.
    class PolygonFrame < Frame
      DEFAULT_STEP = 1.0

      attr_reader :polygon

      # @param polygon [Array<Array<Numeric>>] array of [x, y] vertex
      #   pairs. The polygon is implicitly closed.
      # @param step [Numeric] scan resolution in PDF units; smaller
      #   steps find tighter fits but take longer.
      def initialize(left:, bottom:, width:, height:, polygon: nil, step: DEFAULT_STEP)
        super(left: left, bottom: bottom, width: width, height: height)
        @polygon = polygon || [[left, bottom], [left + width, bottom],
                               [left + width, bottom + height],
                               [left, bottom + height]]
        @step = step.to_f
      end

      # Find the next available area inside the polygon that fits
      # (width, height). Walks row by row from the top of the
      # bounding box downward; at each row y, scans x from left
      # toward the right edge, returning the first (x, y, w, h)
      # position where all four corners of (x, y - h, w, h) are
      # inside the polygon.
      def find_available_area(width, height)
        w = width.to_f
        h = height.to_f
        return nil unless w.positive? && h.positive?

        bbox_top = bounding_box_top
        bbox_bottom = bounding_box_bottom
        bbox_left = bounding_box_left
        bbox_right = bounding_box_right

        y = bbox_top
        while y - h >= bbox_bottom
          x = bbox_left
          while x + w <= bbox_right
            return [x, y, w, h] if contains_rectangle?(x, y - h, w, h)

            x += @step
          end
          y -= @step
        end
        nil
      end

      def bounding_box_top
        @polygon.map { |_x, y| y }.max.to_f
      end

      def bounding_box_bottom
        @polygon.map { |_x, y| y }.min.to_f
      end

      def bounding_box_left
        @polygon.map { |x, _y| x }.min.to_f
      end

      def bounding_box_right
        @polygon.map { |x, _y| x }.max.to_f
      end

      # Point-in-polygon test (ray casting).
      def contains_point?(x, y)
        inside = false
        n = @polygon.length
        i = 0
        j = n - 1
        while i < n
          xi, yi = @polygon[i]
          xj, yj = @polygon[j]
          if ((yi > y) != (yj > y)) &&
              (x < ((xj - xi) * (y - yi) / (yj - yi)) + xi)
            inside = !inside
          end
          j = i
          i += 1
        end
        inside
      end

      def contains_rectangle?(x, y, w, h)
        [
          [x, y],
          [x + w, y],
          [x, y + h],
          [x + w, y + h],
        ].all? { |px, py| contains_point?(px, py) }
      end
    end
  end
end
