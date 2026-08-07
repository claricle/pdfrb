# frozen_string_literal: true

module Pdfrb
  module Layout
    # Breaks a string into Layout::Line instances that fit a given
    # width. Uses real per-glyph widths from the font's AFM or hmtx
    # table when available, falling back to a heuristic estimate.
    class TextLayouter
      attr_reader :style

      def initialize(style)
        @style = style
        @metrics = lookup_metrics
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

      def lookup_metrics
        font_name = @style.font_name
        Pdfrb::Font::MetricsHelper.metrics_for_standard14(font_name)
      rescue StandardError
        nil
      end

      def cluster_width(cluster)
        size = @style.font_size || 10
        upem = @metrics&.units_per_em || 1000

        if @metrics
          total = 0.0
          cluster.each_codepoint do |cp|
            width_in_font_units = glyph_width_in_font_units(cp)
            total += width_in_font_units
          end
          total * size / upem
        else
          # Heuristic fallback when no AFM available.
          size * cluster.length * 0.5
        end
      end

      def glyph_width_in_font_units(codepoint)
        # Map Unicode codepoint → glyph name → AFM width.
        glyph_name = unicode_to_glyph_name(codepoint)
        return 500 unless glyph_name && @metrics

        afm = afm_for(@style.font_name)
        return 500 unless afm

        width = afm.width_for(glyph_name)
        width.positive? ? width : 500
      end

      def unicode_to_glyph_name(codepoint)
        table = begin
          Pdfrb::Font::Encoding::WinAnsiEncoding::TABLE
        rescue StandardError
          nil
        end
        return nil unless table

        table[codepoint]
      end

      def afm_for(font_name)
        @afm_cache ||= {}
        return @afm_cache[font_name] if @afm_cache.key?(font_name)

        @afm_cache[font_name] = Pdfrb::Font::MetricsHelper.afm_for(font_name.to_s)
      end

      def build_line(clusters)
        pieces = clusters.map.with_index { |c, i| [c.ord, i, cluster_width(c)] }
        size = @style.font_size || 10
        ascender = @metrics ? @metrics.ascender(size) : size
        descender = @metrics ? @metrics.descender(size) : -size * 0.2
        Line.new(fragments: [
                   TextFragment.new(
                     pieces: pieces,
                     style: @style,
                     width: pieces.sum { |p| p[2] },
                     height: ascender - descender,
                     y_min: descender,
                     y_max: ascender
                   ),
                 ])
      end
    end
  end
end
