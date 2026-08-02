# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Named graphics-state parameter (s8.4.3) referenced by `gs`
      # operator. Fields: /Type, /LW, /LC, /LJ, /ML, /D, /RI, /SA,
      # /BM, /SM, /CA, /ca, /AIS, /OP, /op, /OPM, /TK, /Font, /TR,
      # /TR2, /HTO, /HTP, /HT, /FL, /UseBlackPtComp, /BG, /BG2,
      # /UCR, /UCR2, /SMask, /HUk.
      class GraphicsStateParameter < Pdfrb::Model::Cos::Dictionary
        arlington_object "GraphicsStateParameter"
        register_type :ExtGState
      end
    end
  end
end
