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
    end
  end
end
