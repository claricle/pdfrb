# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # WebCapturePageSet (ISO 32000-1 §14.10.3, PDF 1.3, deprecated
      # PDF 2.0). A spider content set holding captured pages. The
      # /O array lists page objects converted from HTML.
      class WebCapturePageSet < Pdfrb::Model::Cos::Stream
        arlington_object "WebCapturePageSet"

        # /Type — optional, fixed "SpiderContentSet".
        def type
          value[:Type]&.to_sym
        end

        # /S — required, fixed "SPS" (Spider Page Set).
        def set_type
          value[:S]&.to_sym
        end

        # /ID — required unique identifier.
        def set_id
          value[:ID]
        end

        # /O — required array of indirect references to pages.
        def pages(document = nil)
          refs = value[:O]
          return [] unless refs && document

          arr = refs.is_a?(Pdfrb::Model::PdfArray) ? refs.value : refs
          arr = [arr] unless arr.is_a?(::Array)
          arr.filter_map { |r| r.is_a?(Pdfrb::Model::Reference) ? document.object(r) : r }
        end

        # /CT — optional content type.
        def content_type
          value[:CT]
        end

        # /TS — optional date of capture.
        def timestamp
          value[:TS]
        end
      end

      # WebCaptureInfo (ISO 32000-1 §14.10.2, PDF 1.3, deprecated
      # PDF 2.0). Root dictionary for the Web Capture system, listed
      # in the Catalog's /SpiderInfo key.
      class WebCaptureInfo < Pdfrb::Model::Cos::Dictionary
        arlington_object "WebCaptureInfo"

        # /V — required version number (fixed 1).
        def version
          value[:V]
        end

        # /C — optional array of WebCaptureCommands.
        def commands(document = nil)
          refs = value[:C]
          return [] unless refs && document

          arr = refs.is_a?(Pdfrb::Model::PdfArray) ? refs.value : refs
          arr = [arr] unless arr.is_a?(::Array)
          arr.filter_map do |r|
            resolved = r.is_a?(Pdfrb::Model::Reference) ? document.object(r) : r
            next nil unless resolved && resolved.value.is_a?(::Hash)

            Pdfrb::Model::Type::WebCaptureCommand.new(resolved.value)
          end
        end
      end
    end
  end
end
