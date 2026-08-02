# frozen_string_literal: true

module Pdfrb
  module Content
    module GraphicObject
      # Circular or elliptical arc, approximated with cubic Beziers
      # (s8.3.8.3 in PDF reference). One segment per 90 degrees.
      class Arc
        KAPPA = 0.5522847498.freeze
        private_constant :KAPPA

        attr_reader :cx, :cy, :radius_x, :radius_y,
                    :start_angle, :end_angle

        def initialize(cx:, cy:, radius:, radius_y: nil,
                       start_angle: 0, end_angle: 360)
          @cx = cx.to_f
          @cy = cy.to_f
          @radius_x = radius.to_f
          @radius_y = (radius_y || radius).to_f
          @start_angle = start_angle.to_f
          @end_angle = end_angle.to_f
        end

        # Emit the path operators onto +canvas+ starting with a moveto.
        def draw(canvas)
          steps = tessellate
          return if steps.empty?

          first = steps.first
          canvas.move_to(first[:p0][0], first[:p0][1])
          steps.each do |seg|
            canvas.curve_to(seg[:c1][0], seg[:c1][1],
                            seg[:c2][0], seg[:c2][1],
                            seg[:p3][0], seg[:p3][1])
          end
          canvas
        end

        private

        # One Bezier per 90 degrees (the canonical approximation).
        def tessellate
          segments = []
          return segments if @radius_x.zero? || @radius_y.zero?

          angle = @start_angle
          step = 90.0
          while angle < @end_angle
            seg_end = [angle + step, @end_angle].min
            segments << bezier_segment(angle, seg_end)
            angle = seg_end
            break if angle >= @end_angle
          end
          segments
        end

        def bezier_segment(a0, a1)
          r0 = a0 * Math::PI / 180
          r1 = a1 * Math::PI / 180
          {
            p0: point_at(r0),
            c1: control_at(r0, r1, true),
            c2: control_at(r1, r0, false),
            p3: point_at(r1)
          }
        end

        def point_at(rad)
          [@cx + @radius_x * Math.cos(rad), @cy + @radius_y * Math.sin(rad)]
        end

        def control_at(from, to, forward)
          # Tangent direction at +from+; scale by KAPPA * (angle delta).
          delta = (to - from).abs
          k = KAPPA * (delta / 90.0)
          dx = -@radius_x * Math.sin(from) * k
          dy =  @radius_y * Math.cos(from) * k
          pt = point_at(from)
          forward ? [pt[0] + dx, pt[1] + dy] : [pt[0] - dx, pt[1] - dy]
        end
      end
    end
  end
end
