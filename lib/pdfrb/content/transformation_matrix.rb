# frozen_string_literal: true

module Pdfrb
  module Content
    class TransformationMatrix
      attr_reader :a, :b, :c, :d, :e, :f

      def initialize(a = 1, b = 0, c = 0, d = 1, e = 0, f = 0)
        @a = a.to_f
        @b = b.to_f
        @c = c.to_f
        @d = d.to_f
        @e = e.to_f
        @f = f.to_f
        freeze
      end

      def identity?
        @a == 1 && @b == 0 && @c == 0 && @d == 1 && @e == 0 && @f == 0
      end

      def multiply(other)
        self.class.new(
          @a * other.a + @c * other.b,
          @b * other.a + @d * other.b,
          @a * other.c + @c * other.d,
          @b * other.c + @d * other.d,
          @a * other.e + @c * other.f + @e,
          @b * other.e + @d * other.f + @f,
        )
      end

      def translate(tx, ty)
        multiply(self.class.new(1, 0, 0, 1, tx, ty))
      end

      def scale(sx, sy = sx)
        multiply(self.class.new(sx, 0, 0, sy, 0, 0))
      end

      def rotate(angle_radians)
        cos = Math.cos(angle_radians)
        sin = Math.sin(angle_radians)
        multiply(self.class.new(cos, sin, -sin, cos, 0, 0))
      end

      def skew(fa, fb)
        multiply(self.class.new(1, Math.tan(fa), Math.tan(fb), 1, 0, 0))
      end

      def to_a
        [@a, @b, @c, @d, @e, @f]
      end

      def ==(other)
        other.is_a?(self.class) && to_a == other.to_a
      end
      alias eql? ==
    end
  end
end
