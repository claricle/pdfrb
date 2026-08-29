# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Viewport (ISO 32000-2 §12.7.11, PDF 1.6+). Defines a
      # rectangular region of a page intended for separate display,
      # used for magnifier rectangles, measurement regions, and
      # zoom targets.
      class Viewport < Pdfrb::Model::Cos::Dictionary
        arlington_object "Viewport"

        # /Type — optional, fixed "Viewport".
        def type
          value[:Type]&.to_sym
        end

        # /BBox — required, the viewport rectangle.
        def bbox
          value[:BBox]
        end

        # /Name — optional, human-readable viewport name.
        def name
          value[:Name]
        end

        # /Measure — optional indirect Measure dict (RL for rulers,
        # GEO for geospatial since PDF 2.0).
        def measure(document = nil)
          ref = value[:Measure]
          return nil unless ref && document

          document.resolve(ref)
        end
      end
    end
  end
end
