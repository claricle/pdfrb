# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class GenericAppearance
        attr_reader :annotation, :document

        def initialize(annotation, document)
          @annotation = annotation
          @document = document
        end

        def create_appearance
          rect = annotation[:Rect]
          return nil unless rect.is_a?(::Array) && rect.length == 4

          x0, y0, x1, y1 = rect
          width = (x1 - x0).abs
          height = (y1 - y0).abs
          return nil if width.zero? || height.zero?

          stream = document.add(
            {
              Type: :XObject,
              Subtype: :Form,
              BBox: [0, 0, width, height],
              Matrix: [1, 0, 0, 1, 0, 0],
              Length: 0,
            },
            type: Pdfrb::Model::Cos::Stream
          )
          stream.stream = "q Q\n"
          annotation[:AP] = { N: stream.ref }
          stream
        end
      end
    end
  end
end
