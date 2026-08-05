# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 10 halftone: mesh-based continuous-tone (PDF 1.4+, mostly
      # used for non-square pixel grids).
      class HalftoneType10 < HalftoneType6
        def xsquarestep; self[:Xsquarestep]; end
        def ysquarestep; self[:Ysquarestep]; end
        def center_x; self[:CenterX]; end
        def center_y; self[:CenterY]; end
      end
    end
  end
end
