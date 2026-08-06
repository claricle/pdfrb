# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Linear Distance measure (LD3, s13.6.4).
      class ThreeDMeasureLD3 < ThreeDMeasure
        def annotation1; self[:A1]; end
        def annotation2; self[:A2]; end
        def distance; self[:D]; end
      end
    end
  end
end
