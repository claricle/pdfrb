# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Line annotation (s12.5.6.7). Line between two coordinate pairs.
      class LineAnnotation < MarkupAnnotation
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
          return nil unless line && line.is_a?(Array) && line.size >= 2
          line[0..1]
        end

        def end_point
          return nil unless line && line.is_a?(Array) && line.size >= 4
          line[2..3]
        end

        def has_caption?
          !!caption
        end

        def has_measure?
          !!measure
        end
      end
    end
  end
end
