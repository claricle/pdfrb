# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Watermark annotation (s12.5.6.23). PDF 2.0. Non-printing,
      # non-interactive visual watermark behind/over page content.
      class WatermarkAnnotation < Annotation
        arlington_object "AnnotWatermark"
        def fixed_print?; !!value[:FixedPrint]; end
      end
    end
  end
end
