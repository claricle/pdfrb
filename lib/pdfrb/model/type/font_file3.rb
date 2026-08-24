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

      # FontFile3 with /Subtype /Type1C: CFF glyph program for Type 1
      # fonts (s9.6.6.2).
      class FontFile3Type1 < FontFile3
        arlington_object "FontFile3Type1"
      end

      # FontFile3 with /Subtype /CIDFontType0C: CFF program for CID
      # fonts (s9.7.5.2).
      class FontFile3CIDType0 < FontFile3
        arlington_object "FontFile3CIDType0"
      end

      # FontFile3 with /Subtype /OpenType: OpenType wrapper whose
      # table directory offsets are relative to the stream start
      # (s9.6.6.4).
      class FontFile3OpenType < FontFile3
        arlington_object "FontFile3OpenType"
      end
    end
  end
end
