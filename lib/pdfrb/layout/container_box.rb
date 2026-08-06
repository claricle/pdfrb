# frozen_string_literal: true

module Pdfrb
  module Layout
    # A box that holds an ordered list of child boxes laid out
    # vertically. Each child is fit in turn; if a child doesn't fit
    # in the remaining height, +fit+ returns false and the fitter
    # moves to a new Frame.
    class ContainerBox < Box
      attr_reader :children

      def initialize(children: [], **)
        super(**)
        @children = children
      end

      def fit?(available_width, available_height)
        remaining_height = available_height
        @children.each do |child|
          if child.fit?(available_width, remaining_height)
            remaining_height -= child.height
          else
            return false
          end
        end
        @width = available_width
        @height = available_height - remaining_height
        true
      end

      def draw(canvas, x, y)
        super
        offset_y = y
        @children.each do |child|
          child.draw(canvas, x, offset_y)
          offset_y -= child.height
        end
      end

      def empty?
        @children.empty?
      end
    end
  end
end
