# frozen_string_literal: true

module Pdfrb
  module FontLoader
    module Standard14
      STANDARDS = %w[Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
                     Times-Roman Times-Bold Times-Italic Times-BoldItalic
                     Courier Courier-Bold Courier-Oblique Courier-BoldOblique Symbol ZapfDingbats].freeze

      module_function

      def call(document, name, **_opts)
        return nil unless STANDARDS.include?(name.to_s)

        document.add({ Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
                     type: Pdfrb::Model::Type::FontType1)
      end
    end
  end
end
