# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # WebCaptureCommandSettings (ISO 32000-1 §14.10.4, PDF 1.3,
      # deprecated PDF 2.0). Browser-like settings (get/post data,
      # cookies) for a WebCaptureCommand.
      class WebCaptureCommandSettings < Pdfrb::Model::Cos::Dictionary
        arlington_object "WebCaptureCommandSettings"

        # /G — optional GET parameters dictionary.
        def get_params
          value[:G]
        end

        # /C — optional cookie parameters dictionary.
        def cookie_params
          value[:C]
        end
      end
    end
  end
end
