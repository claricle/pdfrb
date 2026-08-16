# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # AlternateImage (ISO 32000-2 §8.9.5, PDF 1.3+). An alternate
      # image representation used when the primary image's color
      # space isn't available (e.g. a DeviceGray fallback for a
      # DeviceCMYK image on a monochrome printer).
      class AlternateImage < Pdfrb::Model::Cos::Dictionary
        arlington_object "AlternateImage"

        # /Image — required indirect reference to the alternate
        # image XObject.
        def image(document = nil)
          ref = value[:Image]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        # /DefaultForPrinting — optional, default false. When true,
        # the alternate image is used for printing.
        def default_for_printing?
          value[:DefaultForPrinting] == true
        end

        # /OC — optional optional-content group controlling the
        # alternate's visibility (PDF 1.5+).
        def optional_content(document = nil)
          ref = value[:OC]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end
      end
    end
  end
end
