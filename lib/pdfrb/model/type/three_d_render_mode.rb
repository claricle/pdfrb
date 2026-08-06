# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Render Mode (s13.6.4, Table 318-319). Rendering style for
      # 3D objects (solid, wireframe, transparent, etc.).
      class ThreeDRenderMode < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def auxiliary_color; self[:AC]; end
        def face_color; self[:FC]; end
        def opacity; self[:O] || 0.5; end
        def crease_value; self[:CV] || 45; end

        def solid?; subtype == :Solid; end
        def solid_wireframe?; subtype == :SolidWireframe; end
        def transparent?; subtype == :Transparent; end
        def transparent_wireframe?; subtype == :TransparentWireframe; end
        def bounding_box?; subtype == :BoundingBox; end
        def wireframe?; subtype == :Wireframe; end
        def shaded_wireframe?; subtype == :ShadedWireframe; end
        def hidden_wireframe?; subtype == :HiddenWireframe; end
        def vertices?; subtype == :Vertices; end
        def illustration?; subtype == :Illustration; end
        def solid_outline?; subtype == :SolidOutline; end

        def has_opacity?
          opacity.between?(0, 1)
        end
      end
    end
  end
end
