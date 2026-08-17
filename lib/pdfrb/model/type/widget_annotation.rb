# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class WidgetAnnotation < Annotation
        arlington_object "AnnotWidget"
        def field; self[:Parent]; end
        def appearance_stream; self[:AP]; end
        def highlight_mode; self[:H]; end
        def mk; self[:MK]; end
        def action; self[:A]; end
        def additional_actions; self[:AA]; end

        def resolved_field
          ref = field
          return nil unless ref && document

          document.object(ref)
        end

        def button_background_color
          return nil unless mk

          obj = mk.is_a?(Pdfrb::Model::Reference) && document ? document.object(mk) : mk
          obj && obj[:BG]
        end

        def button_caption
          return nil unless mk

          obj = mk.is_a?(Pdfrb::Model::Reference) && document ? document.object(mk) : mk
          obj && obj[:CA]
        end

        def normal_caption
          return nil unless mk

          obj = mk.is_a?(Pdfrb::Model::Reference) && document ? document.object(mk) : mk
          obj && obj[:CA]
        end

        def has_action?
          !!action
        end
      end
    end
  end
end
