# frozen_string_literal: true

module Pdfrb
  module Font
    module Encoding
      # ZapfDingbatsEncoding. Maps byte values to glyph names.
      # Used by the 14th standard font (ZapfDingbats).
      module ZapfDingbatsEncoding
        TABLE = Array.new(256, 0x3F).freeze
      end
    end
  end
end
