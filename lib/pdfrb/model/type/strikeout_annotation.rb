# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # StrikeOut annotation. /Subtype /StrikeOut.
      class StrikeOutAnnotation < TextMarkupAnnotation
        arlington_object "AnnotStrikeOut"
      end
    end
  end
end
