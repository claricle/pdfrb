# frozen_string_literal: true

module Pdfrb
  # Font machinery: encoding tables, CMap parser, TrueType file parser,
  # AFM metrics, font loaders. Consumed by +Document::Fonts+.
  module Font
    autoload :Encoding, "pdfrb/font/encoding"
    autoload :GlyphList, "pdfrb/font/glyph_list"
    autoload :AFMParser, "pdfrb/font/afm_parser"
    autoload :CMap, "pdfrb/font/cmap"
    autoload :TrueType, "pdfrb/font/true_type"
    autoload :Type1, "pdfrb/font/type1"
    autoload :Metrics, "pdfrb/font/metrics_helper"
    autoload :MetricsHelper, "pdfrb/font/metrics_helper"
  end

  # Top-level font loader registry. Extends what +Document::Fonts+
  # already supports by adding TrueType and Type1 loaders.
  autoload :FontLoader, "pdfrb/font_loader"
end
