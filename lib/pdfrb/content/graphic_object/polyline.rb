# frozen_string_literal: true

module Pdfrb
  module Content
    module GraphicObject
      # Open polyline through a list of points.
      class Polyline
        attr_reader :points, :closed

        def initialize(points, closed: false)
          @points = points.map { |p| [p[0].to_f, p[1].to_f] }
          @closed = closed
        end

        def draw(canvas)
          return canvas if @points.empty?

          first = @points.first
          canvas.move_to(first[0], first[1])
          @points.drop(1).each { |x, y| canvas.line_to(x, y) }
          canvas.close_path if @closed
          canvas
        end
      end
    end
  end
end
