# frozen_string_literal: true
module Pdfrb; module FontLoader
  module VariantFromName
    BASE_MAP = {
      "Helvetica" => %w[Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique],
      "Times" => %w[Times-Roman Times-Bold Times-Italic Times-BoldItalic],
      "Courier" => %w[Courier Courier-Bold Courier-Oblique Courier-BoldOblique],
    }.freeze
    module_function
    def call(document, name, **_opts)
      return nil unless name.is_a?(String)
      base = name.sub(/[- ](Bold|Italic|Oblique|BoldItalic|BoldOblique).*/i, "")
      return nil unless BASE_MAP.key?(base)
      idx = name =~ /bold.*italic|italic.*bold/i ? 3 : name =~ /bold/i ? 1 : name =~ /oblique|italic/i ? 2 : 0
      full_name = BASE_MAP[base][idx]
      return nil unless full_name
      document.add({ Type: :Font, Subtype: :Type1, BaseFont: full_name.to_sym },
                   type: Pdfrb::Model::Type::FontType1)
    end
  end
end; end
