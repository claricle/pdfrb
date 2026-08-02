# frozen_string_literal: true

module Pdfrb
  # Font loader registry. Extends the 14-standard-font loader in
  # +Document::Fonts+ with TrueType and Type1 font file loaders.
  module FontLoader
    autoload :TrueType, "pdfrb/font_loader/true_type"
    autoload :Type1, "pdfrb/font_loader/type1"
  end
end
