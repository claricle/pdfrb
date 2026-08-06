# frozen_string_literal: true

module Pdfrb
  module Layout
    # A box that sits inline within a text line (e.g., a styled span
    # or an inline icon). Width + height are fixed; Line arranges it
    # alongside TextFragments.
    class InlineBox < Box
      attr_reader :block

      def initialize(width:, height:, &block)
        super(width: width, height: height)
        @block = block
      end

      def supports_position_flow?
        true
      end

      def draw_content(canvas, x, y)
        @block&.call(canvas, x, y)
      end
    end
  end
end
