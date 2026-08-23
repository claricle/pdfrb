# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # TrueType font file stream (s7.8.3). Holds the TTF/OTF program.
      # Referenced by FontDescriptor /FontFile2.
      class FontFile2 < Pdfrb::Model::Cos::Stream
        arlington_object "FontFile2"
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
    end
  end
end
