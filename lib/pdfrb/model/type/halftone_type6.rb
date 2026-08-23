# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 6 halftone: continuous-tone cell (PDF 1.4+).
      class HalftoneType6 < Halftone
        arlington_object "HalftoneType6"
        def width; self[:Width]; end
        def height; self[:Height]; end
        def width2; self[:Width2]; end
        def height2; self[:Height2]; end
        def transfer_function; self[:TransferFunction]; end
      end
    end
  end
end
