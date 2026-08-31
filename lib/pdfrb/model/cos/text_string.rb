# frozen_string_literal: true

module Pdfrb
  module Model
    module Cos
      # Semantic accessors for spec-defined text strings (s7.9.2.2).
      # On the wire these are UTF-16BE+BOM or PDFDocEncoding bytes —
      # and read-side decryption hands them back as raw bytes — so
      # every accessor that means "this field is text" decodes via
      # this seam instead of relabelling the encoding. The Model
      # itself stays lossless: only semantic accessors decode.
      module TextString
        module_function

        # @return [String] the decoded UTF-8 text, or +raw+ unchanged
        #   when it is not a String (names, arrays, dates pass
        #   through untouched).
        def decode(raw)
          return raw unless raw.is_a?(::String)

          StringEncoding.decode_text(raw)
        end
      end
    end
  end
end
