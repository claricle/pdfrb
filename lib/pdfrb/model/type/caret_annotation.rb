# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Caret annotation (s12.5.6.11). Text-insertion indicator.
      class CaretAnnotation < MarkupAnnotation
        def rd; self[:RD]; end
        def sy; self[:Sy]; end

        def paragraph_style?
          sy&.to_sym == :P
        end

        def new_line_style?
          sy&.to_sym == :None
        end
      end
    end
  end
end
