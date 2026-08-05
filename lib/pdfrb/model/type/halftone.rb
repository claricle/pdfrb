# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Halftone dictionary (s8.7.4). Halftones control how continuous
      # tones are simulated via dot patterns for printing. Six halftone
      # types exist in the PDF spec.
      class Halftone < Pdfrb::Model::Cos::Dictionary
        def halftone_type; self[:HalftoneType]; end
        def halftone_name; self[:HalftoneName]; end

        def type1?; halftone_type == 1; end
        def type5?; halftone_type == 5; end
        def type6?; halftone_type == 6; end
        def type10?; halftone_type == 10; end
        def type16?; halftone_type == 16; end
      end

      # Type 1 halftone: a 1-bit tile sampled from a halftone screen
      # cell defined by frequency, angle, and spot function.
      class HalftoneType1 < Halftone
        def frequency; self[:Frequency]; end
        def angle; self[:Angle]; end
        def spot_function; self[:SpotFunction]; end
        def accurate_screens?; truthy?(self[:AccurateScreens]); end
        def transfer_function; self[:TransferFunction]; end
      end

      # Type 5 halftone: a dictionary mapping colorant name → HalftoneType1.
      class HalftoneType5 < Halftone
        def halftones; self[:Halftones]; end
        def default; self[:Default]; end

        def colorant_count
          return 0 unless halftones

          obj = if halftones.is_a?(Pdfrb::Model::Reference) && document
                  document.object(halftones)
                else
                  halftones
                end
          obj.respond_to?(:value) ? obj.value.size : obj&.size || 0
        end
      end

      # Type 6 halftone: continuous-tone cell (PDF 1.4+).
      class HalftoneType6 < Halftone
        def width; self[:Width]; end
        def height; self[:Height]; end
        def width2; self[:Width2]; end
        def height2; self[:Height2]; end
        def transfer_function; self[:TransferFunction]; end
      end

      # Type 10 halftone: mesh-based continuous-tone (PDF 1.4+, mostly
      # used for non-square pixel grids).
      class HalftoneType10 < HalftoneType6
        def xsquarestep; self[:Xsquarestep]; end
        def ysquarestep; self[:Ysquarestep]; end
        def center_x; self[:CenterX]; end
        def center_y; self[:CenterY]; end
      end

      # Type 16 halftone: more flexible mesh variant (PDF 1.4+).
      class HalftoneType16 < HalftoneType10
      end
    end
  end
end
