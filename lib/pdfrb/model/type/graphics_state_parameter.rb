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

        def line_width; self[:LW]; end
        def line_cap; self[:LC]; end
        def line_join; self[:LJ]; end
        def miter_limit; self[:ML]; end
        def dash_pattern; self[:D]; end
        def rendering_intent; self[:RI]; end
        def stroke_adjustment?; !!self[:SA]; end
        def blend_mode; self[:BM]; end
        def stroking_alpha; self[:CA]; end
        def nonstroking_alpha; self[:ca]; end
        def alpha_source?; !!self[:AIS]; end
        def overprint?; !!self[:OP]; end
        def nonstroking_overprint?; !!self[:op]; end
        def overprint_mode; self[:OPM]; end
        def text_knockout?; !!self[:TK]; end
        def font; self[:Font]; end
        def transfer_function; self[:TR]; end
        def transfer_function2; self[:TR2]; end
        def halftone; self[:HT]; end
        def flatness; self[:FL]; end
        def black_point_compensation; self[:UseBlackPtComp]; end
        def soft_mask; self[:SMask]; end

        def font_name
          return nil unless font
          arr = font.is_a?(Pdfrb::Model::PdfArray) ? font.to_a : font
          arr.is_a?(Array) ? arr[0] : nil
        end

        def font_size
          return nil unless font
          arr = font.is_a?(Pdfrb::Model::PdfArray) ? font.to_a : font
          arr.is_a?(Array) ? arr[1] : nil
        end

        def has_soft_mask?
          !!soft_mask
        end

        def has_transparency?
          (stroking_alpha && stroking_alpha != 1) ||
            (nonstroking_alpha && nonstroking_alpha != 1) ||
            !!blend_mode || !!soft_mask
        end

        def has_font?
          !!font
        end

        def dash_array
          return nil unless dash_pattern
          arr = dash_pattern.is_a?(Pdfrb::Model::PdfArray) ? dash_pattern.to_a : dash_pattern
          return nil unless arr.is_a?(Array) && arr.size >= 1
          arr[0]
        end

        def dash_phase
          return nil unless dash_pattern
          arr = dash_pattern.is_a?(Pdfrb::Model::PdfArray) ? dash_pattern.to_a : dash_pattern
          return nil unless arr.is_a?(Array) && arr.size >= 2
          arr[1]
        end
      end
    end
  end
end
