# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Units (s13.6.4). Scaling factor and unit name for 3D measures.
      class ThreeDUnits < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def unit_name; self[:U]; end
        def scale_factor; self[:SF]; end

        def has_scale_factor?
          !!scale_factor
        end
      end
    end
  end
end
