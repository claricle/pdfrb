# frozen_string_literal: true

module Pdfrb
  module Model
    # 2D affine transformation matrix `[a b c d e f]` per s8.4.4.
    # Composes via right-multiplication (PDF convention).
    # Immutable value object.
    class Matrix
      attr_reader :a, :b, :c, :d, :e, :f

      def initialize(a = 1.0, b = 0.0, c = 0.0, d = 1.0, e = 0.0, f = 0.0)
        @a = a.to_f
        @b = b.to_f
        @c = c.to_f
        @d = d.to_f
        @e = e.to_f
        @f = f.to_f
        freeze
      end

      def self.identity; new; end

      def self.translate(tx, ty); new(1, 0, 0, 1, tx, ty); end

      def self.scale(sx, sy = sx); new(sx, 0, 0, sy, 0, 0); end

      def self.rotate(rad)
        co = Math.cos(rad)
        si = Math.sin(rad)
        new(co, si, -si, co, 0, 0)
      end

      def self.skew(alpha, beta)
        new(1, Math.tan(alpha), Math.tan(beta), 1, 0, 0)
      end

      def self.from_array(arr)
        case arr
        when Matrix then arr
        when PdfArray, Array then new(*arr.take(6))
        else raise ArgumentError, "cannot build Matrix from #{arr.class}"
        end
      end

      # Compose with +other+. Column-vector convention: the product
      # `M1 * M2` first transforms a point by M2, then by M1. Matches
      # PDF's `cm` operator (CTM_new = M_argument * CTM_old).
      def *(other)
        Matrix.new(
          @a * other.a + @c * other.b,
          @b * other.a + @d * other.b,
          @a * other.c + @c * other.d,
          @b * other.c + @d * other.d,
          @a * other.e + @c * other.f + @e,
          @b * other.e + @d * other.f + @f
        )
      end

      def transform_point(x, y)
        [@a * x + @c * y + @e, @b * x + @d * y + @f]
      end

      def identity?
        @a == 1.0 && @b == 0.0 && @c == 0.0 && @d == 1.0 && @e == 0.0 && @f == 0.0
      end

      def to_a
        [@a, @b, @c, @d, @e, @f]
      end

      def ==(other)
        other.is_a?(Matrix) && to_a == other.to_a
      end
      alias eql? ==

      def hash
        to_a.hash
      end

      def inspect
        "#<Matrix a=#{@a} b=#{@b} c=#{@c} d=#{@d} e=#{@e} f=#{@f}>"
      end
    end
  end
end
