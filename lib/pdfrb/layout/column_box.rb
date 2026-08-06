# frozen_string_literal: true

module Pdfrb
  module Layout
    # Lays out children into N columns of equal width separated by
    # gutters. Children flow top-to-bottom in column 1, then wrap to
    # column 2 when column 1 fills, etc.
    class ColumnBox < Box
      attr_reader :children, :columns, :gutter

      def initialize(children:, columns: 2, gutter: 20, **)
        super(**)
        @children = children
        @columns = columns.to_i
        @gutter = gutter.to_f
      end

      def fit?(available_width, available_height)
        column_w = (available_width - (@gutter * (@columns - 1))) / @columns
        @child_heights = []
        remaining_children = @children.dup
        col_heights = Array.new(@columns, 0.0)

        @columns.times do |col_idx|
          col_remaining = available_height
          while remaining_children.any?
            child = remaining_children.first
            if child.fit?(column_w, col_remaining)
              col_heights[col_idx] += child.height
              col_remaining -= child.height
              remaining_children.shift
            else
              break
            end
          end
        end
        @column_width = column_w
        @column_heights = col_heights
        @width = available_width
        @height = available_height
        remaining_children.empty?
      end

      def draw_content(canvas, x, y)
        idx = 0
        @column_heights.each_with_index do |_h, col_idx|
          col_x = x + (col_idx * (@column_width + @gutter))
          col_y = y
          while idx < @children.size
            child = @children[idx]
            break if child_height_in_column(idx, col_idx).nil?

            child.draw(canvas, col_x, col_y)
            col_y -= child.height
            idx += 1
          end
        end
      end

      def empty?
        @children.empty?
      end

      private

      def child_height_in_column(child_idx, col_idx)
        @column_heights[col_idx] if child_idx < @column_heights.size
      end
    end
  end
end
