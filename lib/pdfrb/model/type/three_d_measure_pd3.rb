# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Perpendicular Distance measure (PD3, s13.6.4).
      class ThreeDMeasurePD3 < ThreeDMeasure
        arlington_object "3DMeasurePD3"
        def annotation1; self[:A1]; end
        def annotation2; self[:A2]; end
        def distance; self[:D]; end
        def leader_line_extension; self[:LE]; end
        def leader_line_length; self[:LL]; end

        def has_both_anchors?
          !!annotation1 && !!annotation2
        end
      end
    end
  end
end
