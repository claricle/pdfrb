# frozen_string_literal: true

module Pdfrb
  # Font loader registry. Extends the 14-standard-font loader in
  # +Document::Fonts+ with TrueType and Type1 font file loaders.
  module FontLoader
    autoload :TrueType, "pdfrb/font_loader/true_type"
    autoload :Type1, "pdfrb/font_loader/type1"
    autoload :Standard14, "pdfrb/font_loader/standard14"
    autoload :FromFile, "pdfrb/font_loader/from_file"
    autoload :VariantFromName, "pdfrb/font_loader/variant_from_name"
    autoload :FromConfiguration, "pdfrb/font_loader/from_configuration"
  end
end
