# frozen_string_literal: true

module Pdfrb
  module Layout
    # A table of cells. Each cell holds a Box. Column widths are auto
    # unless specified; row heights computed from content.
    class TableBox < Box
      attr_reader :rows, :column_widths

      def initialize(rows:, column_widths: nil, **)
        super(**)
        @rows = rows
        @column_widths = column_widths
      end

      def fit?(available_width, available_height)
        compute_column_widths(available_width)
        remaining = available_height
        @rows.each do |row|
          row_heights = []
          row.each_with_index do |cell, col|
            cell_w = @column_widths[col]
            cell.fit?(cell_w, remaining) or return false
            row_heights << cell.height
          end
          row_h = row_heights.max || 0
          remaining -= row_h
        end
        @width = available_width
        @height = available_height - remaining
        true
      end

      def draw_content(canvas, x, y)
        offset_y = y
        @rows.each do |row|
          max_h = 0
          offset_x = x
          row.each_with_index do |cell, col|
            cell.draw(canvas, offset_x, offset_y)
            offset_x += @column_widths[col]
            max_h = cell.height if cell.height > max_h
          end
          offset_y -= max_h
        end
      end

      def empty?
        @rows.empty?
      end

      private

      def compute_column_widths(available_width)
        return @column_widths = equal_widths(available_width) if @column_widths.nil?

        @column_widths.map!(&:to_f)
      end

      def equal_widths(available_width)
        col_count = @rows.first&.size || 1
        Array.new(col_count, available_width / col_count)
      end
    end
  end
end
