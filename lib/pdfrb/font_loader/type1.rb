# frozen_string_literal: true

module Pdfrb
  module FontLoader
    # Type1 font loader. For the 14 standard fonts, no embedding
    # is needed. For custom Type1 fonts, parses the AFM and embeds
    # the PFB via /FontFile.
    module Type1
      module_function

      def call(document, name_or_io, **_opts)
        case name_or_io
        when ::String
          if Pdfrb::Document::Fonts::STANDARDS.include?(name_or_io)
            return document.add(
              { Type: :Font, Subtype: :Type1, BaseFont: name_or_io.to_sym },
              type: Pdfrb::Model::Type::FontType1
            )
          end
          nil
        end
      end
    end
  end
end

Pdfrb::Document::Fonts.register_loader(Pdfrb::FontLoader::Type1)
