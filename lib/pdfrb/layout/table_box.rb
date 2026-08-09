# frozen_string literal: true

module Pdfrb
  module Layout
    # A table of cells. Each cell holds a Box. Column widths are auto
    # unless specified; row heights computed from content.
    #
    # Cells may declare +colspan+ / +rowspan+ to occupy multiple
    # columns or rows. Cell entries can be plain Boxes (treated as
    # 1x1 cells) or +TableBox::Cell+ instances created via
    # +TableBox.cell(box, colspan:, rowspan:+).
    class TableBox < Box
      Cell = Struct.new(:box, :colspan, :rowspan, keyword_init: true) do
        def initialize(box:, colspan: 1, rowspan: 1)
          super
        end

        def fit?(*args); box.fit?(*args); end

        def draw(*args); box.draw(*args); end

        def height; box.height; end

        def width; box.width; end
      end

      attr_reader :rows, :column_widths

      # Build a Cell wrapping +box+ with the given spans.
      def self.cell(box, colspan: 1, rowspan: 1)
        Cell.new(box: box, colspan: colspan, rowspan: rowspan)
      end

      def initialize(rows:, column_widths: nil, **)
        super(**)
        @rows = rows.map { |row| row.map { |c| wrap_cell(c) } }
        @column_widths = column_widths
      end

      def fit?(available_width, available_height)
        compute_column_widths(available_width)
        layout_grid!
        fit_rows!(available_height)
        @height <= available_height
      end

      def draw_content(canvas, x, y)
        offset_y = y
        row_heights.each_with_index do |row_h, row_index|
          offset_x = x
          @column_widths.each_with_index do |_w, col_index|
            cell = cell_at(row_index, col_index)
            if cell && origin?(row_index, col_index, cell)
              span_w = spanned_width(col_index, cell.colspan)
              span_h = spanned_height(row_index, cell.rowspan)
              cell.box.fit?(span_w, span_h)
              cell.draw(canvas, offset_x, offset_y)
            end
            offset_x += @column_widths[col_index]
          end
          offset_y -= row_h
        end
      end

      def empty?
        @rows.empty?
      end

      # Height of each row, indexed by row position. Populated by
      # +fit?+.
      def row_heights
        @row_heights || []
      end

      private

      def wrap_cell(value)
        return value if value.is_a?(Cell)

        box = value.is_a?(::Hash) ? value[:box] : value
        colspan = value.is_a?(::Hash) ? (value[:colspan] || 1) : 1
        rowspan = value.is_a?(::Hash) ? (value[:rowspan] || 1) : 1
        Cell.new(box: box, colspan: colspan, rowspan: rowspan)
      end

      def compute_column_widths(available_width)
        return @column_widths = equal_widths(available_width) if @column_widths.nil?

        @column_widths.map!(&:to_f)
      end

      def equal_widths(available_width)
        col_count = @rows.first&.size || 1
        Array.new(col_count, available_width / col_count)
      end

      # Build a (row, col) -> Cell map accounting for spans, so any
      # cell covered by a span from above or to the left resolves to
      # the same Cell instance. @grid[r][c] = the originating Cell.
      def layout_grid!
        @grid = ::Array.new(@rows.size) { ::Array.new(column_count) }
        @origins = {} # [r, c] -> true if this is the top-left of a Cell
        @rows.each_with_index do |row, r|
          c = 0
          row.each do |cell|
            c = next_free_column(r, c)
            place_cell(cell, r, c)
            @origins[[r, c]] = true
            c += cell.colspan
          end
        end
      end

      def next_free_column(row, col)
        col += 1 while @grid[row] && @grid[row][col]
        col
      end

      def place_cell(cell, row, col)
        cell.rowspan.times do |dr|
          cell.colspan.times do |dc|
            r = row + dr
            c = col + dc
            next unless @grid[r] && c < @grid[r].size

            @grid[r][c] = cell
          end
        end
      end

      def column_count
        @column_widths.length
      end

      def cell_at(row, col)
        @grid[row]&.[](col)
      end

      def origin?(row, col, cell)
        # The cell is the origin if the grid position matches the
        # cell's top-left (i.e. the position above and to the left
        # belongs to a different cell or none).
        return true if row.zero? && col.zero?

        above = row.positive? ? @grid[row - 1][col] : nil
        left = col.positive? ? @grid[row][col - 1] : nil
        above != cell && left != cell
      end
      alias is_origin? origin?

      def spanned_width(start_col, colspan)
        span = colspan
        @column_widths[start_col, span].sum
      end

      def spanned_height(start_row, rowspan)
        span = rowspan
        @row_heights[start_row, span]&.sum || 0
      end

      def fit_rows!(available_height)
        @row_heights = compute_row_heights(available_height)
        @height = @row_heights.sum
        @width = @column_widths.sum
        self
      end

      # First pass: compute the natural height of each row by taking
      # the max content height across cells in that row, ignoring
      # rowspan contributions to non-origin rows.
      def compute_row_heights(available_height)
        heights = ::Array.new(@rows.size, 0)
        @rows.each_with_index do |row, r|
          row.each_with_index do |_cell, _c|
            # Handled via grid below for span correctness.
          end
          # Use the grid to skip span-occupied cells.
          column_count.times do |c|
            cell = @grid[r][c]
            next unless cell && origin?(r, c, cell)

            span_w = spanned_width(c, cell.colspan)
            cell.fit?(span_w, available_height)
            cell_h = cell.height.to_f
            # Distribute the height across the rows the cell spans.
            distribute = [(cell_h / cell.rowspan).ceil, 1].max
            cell.rowspan.times do |dr|
              rr = r + dr
              heights[rr] = [heights[rr], distribute].max if heights[rr]
            end
          end
        end
        heights
      end
    end
  end
end
