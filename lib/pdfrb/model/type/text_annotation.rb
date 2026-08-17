# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Sticky note annotation (s12.5.6.10).
      class TextAnnotation < MarkupAnnotation
        arlington_object "AnnotText"
        def state; self[:State]; end
        def state_model; self[:StateModel]; end

        def open?
          !!value[:Open]
        end

        def marked_state?
          state_model&.to_sym == :Marked
        end

        def review_state?
          state_model&.to_sym == :Review
        end
      end
    end
  end
end
