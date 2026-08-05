# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 3 font file stream — the modern container used for CFF
      # (Compact Font Format), OpenType, and CID-keyed fonts.
      # Referenced by FontDescriptor /FontFile3.
      class FontFile3 < Pdfrb::Model::Cos::Stream
        def subtype; self[:Subtype]&.to_sym; end

        def font_program
          decoded_stream&.force_encoding(Encoding::BINARY)
        end

        def cid_font_type0?; subtype == :CIDFontType0C; end
        def open_type?; subtype == :OpenType; end
        def type1c?; subtype == :Type1C; end
        def truetype?; subtype == :TrueType; end
      end
    end
  end
end
