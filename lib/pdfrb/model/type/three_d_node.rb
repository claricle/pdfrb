# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Node (s13.6.4). A node in a 3D model's scene graph.
      class ThreeDNode < Pdfrb::Model::Cos::Dictionary
        arlington_object "3DNode"
        def type; self[:Type]; end
        def name; self[:N]; end
        def opacity; self[:O]; end
        def visible?; truthy?(self[:V]); end
        def matrix; self[:M]; end
        def instance; self[:Instance]; end
        def data; self[:Data]; end
        def render_mode; self[:RM]; end

        def has_render_mode?
          !!render_mode
        end

        def resolved_instance
          ref = instance
          return nil unless ref && document

          document.object(ref)
        end

        def resolved_render_mode
          ref = render_mode
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
