# frozen_string_literal: true

module Pdfrb
  module Content
    module GraphicObject
      # Rectangle with optional rounded corners, drawn as four Bezier
      # curves when radii are non-zero.
      class Rectangle
        KAPPA = 0.5522847498.freeze
        private_constant :KAPPA

        attr_reader :x, :y, :width, :height, :radius

        def initialize(x:, y:, width:, height:, radius: 0)
          @x = x.to_f
          @y = y.to_f
          @width = width.to_f
          @height = height.to_f
          @radius = radius.to_f
        end

        def draw(canvas)
          if @radius.zero?
            canvas.rectangle(@x, @y, @width, @height)
          else
            draw_rounded(canvas)
          end
          canvas
        end

        private

        def draw_rounded(canvas)
          r = @radius
          rx2 = @x + @width
          ry2 = @y + @height
          rx = @x
          ry = @y
          k = r * KAPPA
          canvas.move_to(rx + r, ry)
          canvas.line_to(rx2 - r, ry)
          canvas.curve_to(rx2 - k, ry, rx2, ry + r - k, rx2, ry + r)
          canvas.line_to(rx2, ry2 - r)
          canvas.curve_to(rx2, ry2 - r + k, rx2 - r + k, ry2, rx2 - r, ry2)
          canvas.line_to(rx + r, ry2)
          canvas.curve_to(rx + r - k, ry2, rx, ry2 - r + k, rx, ry2 - r)
          canvas.line_to(rx, ry + r)
          canvas.curve_to(rx, ry + r - k, rx + r - k, ry, rx + r, ry)
        end
      end
    end
  end
end
