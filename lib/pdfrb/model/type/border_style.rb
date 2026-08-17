# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # BorderStyle (ISO 32000-2 §12.5.4, PDF 1.2+). The /BS dict on
      # an annotation, controlling line width, style, and dash
      # pattern.
      class BorderStyle < Pdfrb::Model::Cos::Dictionary
        arlington_object "BorderStyle"

        # /W — optional, border width in points (default 1).
        def width
          value[:W] || 1
        end

        # /S — optional, border style name (default :S).
        # S = solid, D = dashed, B = beveled, I = inset, U = underline.
        def style
          (value[:S] || :S).to_sym
        end

        # /D — optional, dash pattern array (only when style == :D).
        def dash
          value[:D]
        end

        def solid?; style == :S; end
        def dashed?; style == :D; end
        def beveled?; style == :B; end
        def inset?; style == :I; end
        def underline?; style == :U; end
      end
    end
  end
end
