# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 1 font file stream (s7.8.2). Holds the Type1 / Type1C
      # font program. Referenced by FontDescriptor /FontFile.
      class FontFile < Pdfrb::Model::Cos::Stream
        def length1; self[:Length1]; end
        def length2; self[:Length2]; end
        def length3; self[:Length3]; end
        def subtype; self[:Subtype]; end

        def has_clear_text_mark?
          !!length1 && length1.positive?
        end

        def has_encrypted_portion?
          !!length2 && length2.positive?
        end

        def font_program
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end

      # TrueType font file stream (s7.8.3). Holds the TTF/OTF program.
      # Referenced by FontDescriptor /FontFile2.
      class FontFile2 < Pdfrb::Model::Cos::Stream
        def length1; self[:Length1]; end
        def subtype; self[:Subtype]; end

        def font_program
          decoded_stream&.force_encoding(Encoding::BINARY)
        end

        def magic
          return nil unless stream

          stream.byteslice(0, 4)
        end

        def truetype?
          magic == "\x00\x01\x00\x00".b || magic == "true".b
        end

        def opentype?
          magic == "OTTO".b
        end
      end

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
