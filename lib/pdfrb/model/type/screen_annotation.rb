# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Screen annotation (s12.5.6.18). Holds media played via Action
      # triggers. /Subtype /Screen.
      class ScreenAnnotation < Annotation
        def attachment_point; self[:AP]; end
        def media_type; self[:T]; end
        def actions; self[:AA]; end

        def has_media?
          !!media_type
        end
      end
    end
  end
end
