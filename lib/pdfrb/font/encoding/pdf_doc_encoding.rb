# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      # PDFDocEncoding table (Appendix D.2). Reuses the StringEncoding
      # table already defined in +Cos::StringEncoding+ to avoid duplication.
      module PDFDocEncoding
        TABLE = Pdfrb::Model::Cos::StringEncoding::PDF_DOC_ENCODING
          .each_with_index.each_with_object(Array.new(256, nil)) do |((cp, byte), _), arr|
            arr[byte] = cp if cp
          end.freeze
      end
    end
  end
end
