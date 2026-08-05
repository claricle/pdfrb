# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Text-markup annotations (s12.5.6.10). Common base for Highlight,
      # Underline, Squiggly, StrikeOut — all share /QuadPoints.
      class TextMarkupAnnotation < MarkupAnnotation
        def quad_points; self[:QuadPoints]; end

        def quad_point_count
          return 0 unless quad_points
          arr = quad_points.is_a?(Pdfrb::Model::PdfArray) ? quad_points.to_a : quad_points
          arr.is_a?(Array) ? arr.size / 8 : 0
        end

        def each_quad
          return enum_for(:each_quad) unless block_given?
          return unless quad_points

          arr = quad_points.is_a?(Pdfrb::Model::PdfArray) ? quad_points.to_a : quad_points
          return unless arr.is_a?(Array)

          arr.each_slice(8) { |quad| yield quad }
        end
      end

      # Highlight annotation. /Subtype /Highlight.
      class HighlightAnnotation < TextMarkupAnnotation
      end

      # Underline annotation. /Subtype /Underline.
      class UnderlineAnnotation < TextMarkupAnnotation
      end

      # Squiggly annotation. /Subtype /Squiggly.
      class SquigglyAnnotation < TextMarkupAnnotation
      end

      # StrikeOut annotation. /Subtype /StrikeOut.
      class StrikeOutAnnotation < TextMarkupAnnotation
      end
    end
  end
end
