# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 3 glyph font (s9.6.5). /Subtype /Type3, /CharProcs,
      # /Resources, /FontBBox, /FontMatrix, /Encoding, /Widths.
      class FontType3 < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontType3"
      end
    end
  end
end
