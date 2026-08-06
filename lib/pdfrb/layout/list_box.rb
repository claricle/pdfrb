# frozen_string_literal: true

module Pdfrb
  module Layout
    # Roman numeral converter. Extracted as a standalone helper so
    # +ListBox+ and +PageLabel+ (model layer) can share it.
    class RomanNumeral
      MAPPINGS = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
                  [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
                  [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]].freeze

      def self.convert(n)
        return "0" if n <= 0

        result = +""
        MAPPINGS.each do |value, symbol|
          while n >= value
            result << symbol
            n -= value
          end
        end
        result
      end
    end

    # A list of items, each rendered with a marker (bullet, decimal,
    # alpha, roman, etc.). Children are boxes (typically TextBox).
    class ListBox < Box
      attr_reader :items, :marker_type

      MARKERS = {
        bullet: "•",
        disc: "•",
        circle: "○",
        square: "▪",
        decimal: ->(i) { "#{i + 1}." },
        lower_alpha: ->(i) { "#{('a'.ord + i).chr}." },
        upper_alpha: ->(i) { "#{('A'.ord + i).chr}." },
        lower_roman: ->(i) { "#{RomanNumeral.convert(i + 1).downcase}." },
        upper_roman: ->(i) { "#{RomanNumeral.convert(i + 1)}." },
      }.freeze

      def initialize(items:, marker_type: :bullet, **)
        super(**)
        @items = items
        @marker_type = marker_type
      end

      def fit?(available_width, available_height)
        marker_w = 20.0
        content_w = available_width - marker_w
        remaining = available_height
        @items.each do |item|
          return false unless item.fit?(content_w, remaining)

          remaining -= item.height
        end
        @width = available_width
        @height = available_height - remaining
        true
      end

      def draw_content(canvas, x, y)
        marker_w = 20.0
        offset_y = y
        @items.each_with_index do |item, i|
          marker_text(canvas, x, offset_y, i)
          item.draw(canvas, x + marker_w, offset_y)
          offset_y -= item.height
        end
      end

      def empty?
        @items.empty?
      end

      private

      def marker_text(canvas, x, y, index)
        marker = MARKERS[@marker_type] || MARKERS[:bullet]
        text = marker.is_a?(Proc) ? marker.call(index) : marker
        canvas.text(text, at: [x, y], font: :Helvetica,
                          size: @style.font_size || 10)
      end
    end
  end
end
