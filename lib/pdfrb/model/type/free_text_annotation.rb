# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Free-text annotation (s12.5.6.6). Text shown directly on the page.
      class FreeTextAnnotation < MarkupAnnotation
        arlington_object "AnnotFreeText"
        def default_appearance; self[:DA]; end
        def q; self[:Q]; end
        def rc; self[:RC]; end
        def ds; self[:DS]; end
        def cl; self[:CL]; end
        def it; self[:IT]; end
        def be; self[:BE]; end
        def rd; self[:RD]; end
        def style_string; default_appearance; end

        def text_alignment
          case q
          when 1 then :center
          when 2 then :right
          when 3 then :justify
          else :left
          end
        end

        def callout?
          !!cl
        end

        def border_effect?
          !!be
        end
      end
    end
  end
end
