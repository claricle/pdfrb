# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Redaction annotation (s12.5.6.16). Marks content for removal.
      class RedactAnnotation < MarkupAnnotation
        def overlay_text; self[:OverlayText]; end
        def repeat_overlay?; !!self[:Repeat]; end
        def quadding; self[:Q]; end
        def interior_color; self[:IC]; end
        def da; self[:DA]; end

        def alignment
          case quadding
          when 0 then :left
          when 1 then :center
          when 2 then :right
          else :left
          end
        end

        def has_overlay_text?
          !!overlay_text && (!overlay_text.is_a?(String) || !overlay_text.empty?)
        end
      end
    end
  end
end
