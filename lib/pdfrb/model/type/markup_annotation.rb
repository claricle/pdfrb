# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class MarkupAnnotation < Annotation
        def title; self[:T]; end
        def popup; self[:Popup]; end
        def rich_contents; self[:RC]; end
        def creation_date; self[:CreationDate]; end
        def subject; self[:Subj]; end
        def intent; self[:IT]; end
        def in_reply_to; self[:IRT]; end
        def reply_type; self[:RT]; end
        def external_data; self[:ExData]; end
        def opacity; self[:CA]; end
        def interior_color; self[:IC]; end

        def open?
          return false unless popup

          obj = popup.is_a?(Pdfrb::Model::Reference) && document ? document.object(popup) : popup
          obj && obj[:Open]
        end

        def reply?
          !!in_reply_to
        end

        def group_reply?
          reply_type&.to_sym == :Group
        end
      end
    end
  end
end
