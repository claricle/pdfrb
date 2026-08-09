# frozen_string_literal: true

module Pdfrb
  module Layout
    # Polygon-aware Frame: extends Frame to compute available area
    # against an arbitrary polygon shape, not just a rectangle.
    # Useful for L-shaped text regions, text-around-image, and
    # irregular page layouts.
    #
    # The default Frame.find_available_area always returns the
    # top-left rectangle; this subclass walks the polygon edges to
    # find the largest inscribed rectangle of (width x height).
    class PolygonFrame < Frame
      attr_reader :polygon

      # @param polygon [Array<Array<Numeric>>] array of [x, y] vertex
      #   pairs. The polygon is implicitly closed.
      def initialize(left:, bottom:, width:, height:, polygon: nil)
        super(left: left, bottom: bottom, width: width, height: height)
        @polygon = polygon || [[left, bottom], [left + width, bottom],
                               [left + width, bottom + height],
                               [left, bottom + height]]
      end

      # Find the next available area inside the polygon that fits
      # (width, height). Walks polygon edges top-to-bottom.
      def find_available_area(width, height)
        w = width.to_f
        h = height.to_f
        # Naive implementation: scan from top of bounding box
        # downward, finding the first y where the polygon contains
        # the (left, y - h, w, h) rectangle.
        bbox_top = bounding_box_top
        bbox_bottom = bounding_box_bottom
        y = bbox_top
        while y - h >= bbox_bottom
          if contains_rectangle?(@left, y - h, w, h)
            return [@left, y, w, h]
          end

          y -= 1.0
        end
        nil
      end

      def bounding_box_top
        @polygon.map { |_x, y| y }.max.to_f
      end

      def bounding_box_bottom
        @polygon.map { |_x, y| y }.min.to_f
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
        # Check all four corners.
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
