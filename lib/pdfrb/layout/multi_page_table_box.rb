# frozen_string_literal: true

module Pdfrb
  module Layout
    # Multi-page table: wraps a single TableBox's worth of rows and
    # splits it into per-page fragments when it doesn't fit a single
    # frame. Each fragment is a TableBox whose fit? returns true for
    # the available height; the splitter yields them in document
    # order, optionally repeating a header row on each fragment.
    #
    # This is intentionally a thin coordinator: it doesn't re-layout
    # cells; it just partitions rows. The actual row drawing is
    # delegated to TableBox, so col/row spans continue to work — but
    # spans that cross a split boundary are clamped at the split
    # (their rowspan is truncated to the rows that fit).
    class MultiPageTableBox < Box
      DEFAULT_MIN_ROWS_PER_PAGE = 3
      DEFAULT_REPEAT_HEADER = true

      attr_reader :rows, :column_widths, :header_row_count, :min_rows_per_page

      # @param rows [Array<Array<Pdfrb::Layout::TableBox::Cell, Box>>]
      #   the full table content.
      # @param column_widths [Array<Numeric>, nil] explicit widths.
      # @param header_row_count [Integer] number of leading rows to
      #   repeat at the top of each page fragment. 0 disables.
      # @param min_rows_per_page [Integer] minimum number of body
      #   rows on each page; if the split would produce fewer, the
      #   fragment is deferred to the next page.
      def initialize(rows:, column_widths: nil, header_row_count: 0,
                     min_rows_per_page: DEFAULT_MIN_ROWS_PER_PAGE, **)
        super(**)
        @rows = rows
        @column_widths = column_widths
        @header_row_count = header_row_count
        @min_rows_per_page = min_rows_per_page
        @fragments = nil
      end

      # Returns the per-page fragments as an Array of TableBox. The
      # first fragment fits within +available_height+; each
      # subsequent fragment fits within +page_height+ (the next page
      # may have more room because there's no preceding content).
      #
      # Mutates internal state (the @fragments cache). Idempotent for
      # the same dimensions.
      def fragments(available_width:, first_page_height:, later_page_height:)
        compute_column_widths(available_width)
        header = @header_row_count.positive? ? @rows.first(@header_row_count) : []
        body = @rows[@header_row_count..] || []

        fragments = []
        cursor = 0
        first_pass = true
        while cursor < body.length
          available = first_pass ? first_page_height : later_page_height
          max_count = rows_that_fit(body, cursor, available)
          count = if max_count.zero? && cursor.zero?
                    # First fragment must contain at least one row
                    # even if it overflows; otherwise the table is
                    # undrawable.
                    [@min_rows_per_page, body.length].min
                  elsif max_count < @min_rows_per_page
                    # Force at least min_rows_per_page (may overflow).
                    [@min_rows_per_page, body.length - cursor].min
                  else
                    max_count
                  end
          break if count.zero?

          chunk = body[cursor, count]
          rows_for_fragment = header + chunk
          fragments << build_fragment(rows_for_fragment)
          cursor += count
          first_pass = false
        end
        fragments
      end

      def fit?(available_width, available_height)
        @fragments = fragments(available_width: available_width,
                               first_page_height: available_height,
                               later_page_height: available_height)
        @fragments.any?
      end

      def draw_content(canvas, x, y)
        return if @fragments.nil? || @fragments.empty?

        # Draw the first fragment in place; the Composer is
        # responsible for placing subsequent fragments on later
        # pages by calling draw on each fragment directly.
        offset_y = y
        @fragments.each do |frag|
          frag.draw(canvas, x, offset_y)
          offset_y -= frag.height
        end
      end

      # Iterate fragments. Yields each TableBox fragment; if a block
      # is absent, returns an Enumerator. Useful for the Composer
      # flow: the first fragment is drawn at the current cursor,
      # subsequent fragments trigger a page break.
      def each_fragment(&block)
        return enum_for(:each_fragment) unless block

        @fragments.each(&block)
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

      # Measure how many rows from +body+ starting at +cursor+ fit
      # in +available_height+ using the computed column widths.
      def rows_that_fit(body, cursor, available_height)
        remaining = available_height.to_f
        count = 0
        body[cursor..].each_with_index do |row, _i|
          row_h = measure_row_height(row)
          break if (remaining - row_h).negative?

          remaining -= row_h
          count += 1
        end
        count
      end

      # Estimate row height as the max natural height of any cell
      # in the row, given the column widths.
      def measure_row_height(row)
        heights = row.map.with_index do |cell, _col|
          cell_box = cell.is_a?(TableBox::Cell) ? cell.box : cell
          next 0 unless cell_box.is_a?(Pdfrb::Layout::Box)

          cell_box.height.to_f
        end
        heights.max || 14.0
      end

      def build_fragment(rows)
        TableBox.new(rows: rows, column_widths: @column_widths&.dup)
      end
    end
  end
end
