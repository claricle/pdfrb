# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Line annotation (s12.5.6.7). Line between two coordinate pairs.
      class LineAnnotation < MarkupAnnotation
        arlington_object "AnnotLine"
        def line; self[:L]; end
        def le; self[:LE]; end
        def line_endings; le; end
        def interior_color; self[:IC]; end
        def caption; self[:Cap]; end
        def measure; self[:Measure]; end
        def border_style; self[:BS]; end
        def border; self[:Border]; end
        def co; self[:CO]; end
        def cp; self[:CP]; end
        def ll; self[:LL]; end
        def lle; self[:LLE]; end
        def it; self[:IT]; end

        def start_point
          l = line_array
          return nil unless l && l.size >= 2

          l[0..1]
        end

        def end_point
          l = line_array
          return nil unless l && l.size >= 4

          l[2..3]
        end

        def has_caption?
          !!caption
        end

        def has_measure?
          !!measure
        end

        private

        def line_array
          l = line
          return l.to_a if l.is_a?(Pdfrb::Model::PdfArray)
          return l if l.is_a?(::Array)

          nil
        end
      end
    end
  end
end
