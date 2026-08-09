# frozen_string_literal: true

module Pdfrb
  module Layout
    # Multi-cell text layout: flows text across an arbitrary shape
    # defined by a series of horizontal bands. Used for magazine-
    # style layouts where text wraps around images, sidebars, or
    # irregular page regions.
    #
    # A band is a rectangular region with [x, y, width, height] in
    # PDF coordinates (origin bottom-left). The layouter fills bands
    # top-to-bottom, left-to-right.
    class MultiCellTextLayout
      attr_reader :bands, :style

      def initialize(bands:, style: Style.new(:base))
        @bands = bands
        @style = style
      end

      # Lay out +text+ into the bands. Returns an Array of
      # [band_index, lines] pairs where each line is a Layout::Line.
      def layout(text)
        layouter = TextLayouter.new(@style)
        result = []
        words = text.to_s.split(/(\s+)/)
        current_band = 0
        cursor_height = band_height(current_band)
        current_chunk = +""

        words.each do |word|
          trial = current_chunk + word
          lines = layouter.layout(trial, band_width(current_band))
          total_h = lines.sum { |l| line_height(l) }

          if total_h > cursor_height && current_band < @bands.length - 1
            # Flush current chunk to current band
            result << [current_band, layouter.layout(current_chunk, band_width(current_band))] if current_chunk.length.positive?
            current_band += 1
            cursor_height = band_height(current_band)
            current_chunk = +word
          else
            current_chunk = trial
          end
        end
        result << [current_band, layouter.layout(current_chunk, band_width(current_band))] if current_chunk.length.positive?
        result
      end

      private

      def band_width(index)
        @bands[index] ? @bands[index][2].to_f : 100.0
      end

      def band_height(index)
        @bands[index] ? @bands[index][3].to_f : 100.0
      end

      def line_height(_line)
        @style.font_size ? @style.font_size * 1.2 : 14.0
      end
    end
  end
end
