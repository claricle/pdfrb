# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # TrapRegion (Adobe TechNote 5620 §5.34, PDF 1.3, deprecated
      # PDF 2.0). A trapping (prepress) region on a page. Referenced
      # from /Annots as /Subtype /Traps or from separation profiles.
      class TrapRegion < Pdfrb::Model::Cos::Dictionary
        arlington_object "TrapRegion"

        # /TP — required name: trapping parameters version.
        def trap_parameters
          value[:TP]
        end

        # /TZ — optional array-of-arrays of numbers defining trap
        # zones.
        def trap_zones
          value[:TZ]
        end
      end
    end
  end
end
