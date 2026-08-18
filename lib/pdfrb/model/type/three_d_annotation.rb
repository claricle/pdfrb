# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D annotation (s13.6.2, PDF 1.6+). /Subtype /3D. Hosts a 3D
      # artwork stream, activation behaviour, and viewing state.
      class ThreeDAnnotation < Annotation
        arlington_object "Annot3D"

        def artwork; self[:"3DD"]; end
        def default_view; self[:"3DV"]; end
        def activation; self[:"3DA"]; end
        def interactive; self[:"3DI"]; end
        def view_box; self[:"3DB"]; end
        def units; self[:"3DU"]; end
        def geometry; self[:GEO]; end

        def interactive?
          interactive == true
        end

        def has_measure?
          !geometry.nil?
        end

        def default_view_name?
          default_view.is_a?(Symbol) || default_view.is_a?(String)
        end
      end
    end
  end
end
