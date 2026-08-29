# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # WebCaptureImageSet (ISO 32000-1 §14.10.3, PDF 1.3, deprecated
      # PDF 2.0). A spider content set holding captured images. The
      # /O array lists image XObjects; /R gives the crawl depth for
      # each image.
      class WebCaptureImageSet < Pdfrb::Model::Cos::Stream
        arlington_object "WebCaptureImageSet"

        # /Type — optional, fixed "SpiderContentSet".
        def type
          value[:Type]&.to_sym
        end

        # /S — required, fixed "SIS" (Spider Image Set).
        def set_type
          value[:S]&.to_sym
        end

        # /ID — required unique identifier.
        def set_id
          value[:ID]
        end

        # /O — required array of indirect references to images.
        def images(document = nil)
          refs = value[:O]
          return [] unless refs && document

          arr = refs.is_a?(Pdfrb::Model::PdfArray) ? refs.value : refs
          arr = [arr] unless arr.is_a?(::Array)
          arr.filter_map { |r| document.resolve(r) }
        end

        # /CT — optional content type (RFC 2045).
        def content_type
          value[:CT]
        end

        # /TS — optional date of capture.
        def timestamp
          value[:TS]
        end
      end
    end
  end
end
