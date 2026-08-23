# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # ToUnicode CMap stream (s9.10.3). Maps glyph codes to Unicode
      # strings for text extraction.
      class ToUnicodeCMapStream < Pdfrb::Model::Cos::Stream
        arlington_object "ToUnicodeCMapStream"
        def type; self[:Type]; end

        def cmap_source
          decoded_stream&.force_encoding(Encoding::BINARY)
        end

        def has_codespace?
          return false unless cmap_source

          cmap_source.include?("begincodespacerange")
        end
      end
    end
  end
end
