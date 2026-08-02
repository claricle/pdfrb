# frozen_string_literal: true

module Pdfrb
  module Model
    # PDF rectangle (s7.9.5): 4-number array `[llx lly urx ury]`.
    # Immutable value object.
    class Rectangle
      attr_reader :llx, :lly, :urx, :ury

      def initialize(llx, lly, urx, ury)
        @llx = llx.to_f
        @lly = lly.to_f
        @urx = urx.to_f
        @ury = ury.to_f
        freeze
      end

      def self.from_array(arr)
        case arr
        when Rectangle then arr
        when PdfArray, Array then new(arr[0], arr[1], arr[2], arr[3])
        else raise ArgumentError, "cannot build Rectangle from #{arr.class}"
        end
      end

      def width;  @urx - @llx; end
      def height; @ury - @lly; end
      def left;   @llx; end
      def bottom; @lly; end
      def right;  @urx; end
      def top;    @ury; end

      def origin; [@llx, @lly]; end
      def corner; [@urx, @ury]; end

      def to_a
        [@llx, @lly, @urx, @ury]
      end

      def ==(other)
        other.is_a?(Rectangle) && to_a == other.to_a
      end
      alias eql? ==

      def hash
        to_a.hash
      end

      def inspect
        "#<Rectangle llx=#{@llx} lly=#{@lly} urx=#{@urx} ury=#{@ury}>"
      end
    end
  end
end
