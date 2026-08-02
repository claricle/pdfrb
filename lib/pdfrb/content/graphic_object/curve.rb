# frozen_string_literal: true

module Pdfrb
  module Content
    module GraphicObject
      # Cubic Bezier curve through one start point, two control
      # points, and one end point. Convenience wrapper around
      # +canvas.curve_to+ for users that prefer object form.
      class Curve
        attr_reader :start, :c1, :c2, :endpoint

        def initialize(start:, c1:, c2:, endpoint:)
          @start = [start[0].to_f, start[1].to_f]
          @c1 = [c1[0].to_f, c1[1].to_f]
          @c2 = [c2[0].to_f, c2[1].to_f]
          @endpoint = [endpoint[0].to_f, endpoint[1].to_f]
        end

        def draw(canvas)
          canvas.move_to(@start[0], @start[1])
          canvas.curve_to(@c1[0], @c1[1], @c2[0], @c2[1],
                          @endpoint[0], @endpoint[1])
          canvas
        end
      end
    end
  end
end
