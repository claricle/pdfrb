# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Angle Distance measure (AD3, s13.6.4).
      class ThreeDMeasureAD3 < ThreeDMeasure
        arlington_object "3DMeasureAD3"
        def annotation1; self[:A1]; end
        def annotation2; self[:A2]; end
        def angle; self[:A]; end
      end
    end
  end
end
