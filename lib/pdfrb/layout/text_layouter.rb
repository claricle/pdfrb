# frozen_string_literal: true

module Pdfrb
  module Layout
    # Breaks a string into Layout::Line instances that fit a given
    # width. Greedy first-fit with Unicode cluster awareness.
    class TextLayouter
      attr_reader :style

      def initialize(style)
        @style = style
      end

      # @param text [String] the text to lay out.
      # @param width [Float] target line width in PDF units.
      # @return [Array<Line>] lines, each fitting in +width+.
      def layout(text, width)
        clusters = text.to_s.grapheme_clusters
        return [] if clusters.empty?

        lines = []
        current = []
        current_width = 0.0
        clusters.each do |cluster|
          cw = cluster_width(cluster)
          if current_width + cw > width && !current.empty?
            lines << build_line(current)
            current = []
            current_width = 0.0
          end
          current << cluster
          current_width += cw
        end
        lines << build_line(current) unless current.empty?
        lines
      end

      private

      def cluster_width(cluster)
        size = @style.font_size || 10
        size * cluster.length * 0.5
      end

      def build_line(clusters)
        pieces = clusters.map.with_index { |c, i| [c.ord, i, cluster_width(c)] }
        size = @style.font_size || 10
        Line.new(fragments: [
                   TextFragment.new(
                     pieces: pieces,
                     style: @style,
                     width: pieces.sum { |p| p[2] },
                     height: size * 1.2,
                     y_min: -size * 0.2,
                     y_max: size
                   ),
                 ])
      end
    end
  end
end
