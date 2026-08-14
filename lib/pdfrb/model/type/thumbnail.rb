# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Thumbnail image stream (ISO 32000-2 §12.3.4). A small image
      # XObject rendered at reduced resolution for use in viewer
      # navigation panels. Attached to a page via the /Thumb key.
      class Thumbnail < Pdfrb::Model::Cos::Stream
        arlington_object "Thumbnail"

        # /Width — required.
        def width
          value[:Width]
        end

        # /Height — required.
        def height
          value[:Height]
        end

        # /ColorSpace — required unless /ImageMask true.
        def color_space
          value[:ColorSpace]
        end

        # /BitsPerComponent — required.
        def bits_per_component
          value[:BitsPerComponent]
        end

        # /Filter — optional; a named filter or array of filters.
        def filter
          value[:Filter]
        end

        def dimensions
          [width, height]
        end
      end
    end
  end
end
