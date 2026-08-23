# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 1 halftone: a 1-bit tile sampled from a halftone screen
      # cell defined by frequency, angle, and spot function.
      class HalftoneType1 < Halftone
        arlington_object "HalftoneType1"
        def frequency; self[:Frequency]; end
        def angle; self[:Angle]; end
        def spot_function; self[:SpotFunction]; end
        def accurate_screens?; truthy?(self[:AccurateScreens]); end
        def transfer_function; self[:TransferFunction]; end
      end
    end
  end
end
