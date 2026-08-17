# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Polyline annotation (s12.5.6.9). Open polyline (not closed).
      class PolylineAnnotation < MarkupAnnotation
        arlington_object "AnnotPolyLine"
        def vertices; self[:Vertices]; end
        def line_endings; self[:LE]; end
        def interior_color; self[:IC]; end
        def border_style; self[:BS]; end
        def border; self[:Border]; end
        def measure; self[:Measure]; end
        def intent; self[:IT]; end

        def vertex_count
          return 0 unless vertices

          arr = vertices.is_a?(Pdfrb::Model::PdfArray) ? vertices.to_a : vertices
          arr.is_a?(Array) ? arr.size : 0
        end

        def has_measure?
          !!measure
        end
      end
    end
  end
end
