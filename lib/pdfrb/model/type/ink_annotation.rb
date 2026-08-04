# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class InkAnnotation < Annotation
        def content; self[:Contents]; end
        def popup; self[:Popup]; end
        def color; self[:C]; end
      end
    end
  end
end
