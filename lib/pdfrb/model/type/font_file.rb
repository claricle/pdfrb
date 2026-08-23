# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type 1 font file stream (s7.8.2). Holds the Type1 / Type1C
      # font program. Referenced by FontDescriptor /FontFile.
      class FontFile < Pdfrb::Model::Cos::Stream
        arlington_object "FontFile"
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
    end
  end
end
