# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class PolygonPolyline < Annotation
        def vertices; self[:Vertices]; end
        def line_ending_styling; self[:LE]; end
        def interior_color; self[:IC]; end
        def fill?; self[:Subtype] == :Polygon; end
      end
    end
  end
end
