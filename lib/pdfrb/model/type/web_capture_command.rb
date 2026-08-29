# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # WebCaptureCommand (ISO 32000-1 §14.10.4, PDF 1.3, deprecated
      # PDF 2.0). Describes a URL retrieval for the Web Capture
      # (spider) system: what to fetch, how to fetch it, and what
      # form data to post.
      class WebCaptureCommand < Pdfrb::Model::Cos::Dictionary
        arlington_object "WebCaptureCommand"

        # /URL — required ASCII string to retrieve.
        def url
          value[:URL]
        end

        # /L — optional integer, delay before retrieval in seconds
        # (default 1). Must be >= 1.
        def delay_seconds
          value[:L] || 1
        end

        # /F — optional bitmask of flags.
        def flags
          value[:F] || 0
        end

        # /CT — optional content type of posted data (RFC 2045).
        def content_type
          value[:CT] || "application/x-www-form-urlencoded"
        end

        # /S — optional WebCaptureCommandSettings dict.
        def settings(document = nil)
          ref = value[:S]
          return nil unless ref && document

          resolved = document.resolve(ref)
          return nil unless resolved

          Pdfrb::Model::Type::WebCaptureCommandSettings.new(resolved.value)
        end
      end
    end
  end
end
