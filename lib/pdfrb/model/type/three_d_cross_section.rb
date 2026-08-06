# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Cross Section (s13.6.4). Plane cutaway view of a 3D model.
      class ThreeDCrossSection < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def center; self[:C]; end
        def orientation; self[:O]; end
        def plane_opacity; self[:PO] || 0.5; end
        def plane_color; self[:PC]; end
        def intersection_visible?; truthy?(self[:IV]); end
        def plane_visible?; truthy?(self[:PV]); end
        def show_transparent?; truthy?(self[:ST]); end
        def show_cut?; truthy?(self[:SC]); end
        def intersection_color; self[:IC]; end

        def has_plane_color?
          !!plane_color
        end
      end
    end
  end
end
