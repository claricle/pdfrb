# frozen_string_literal: true

module Pdfrb
  module Source
    # Reads the Linearization dictionary (Annex F) that lives on the
    # first indirect object of a linearized PDF. Exposes the
    # page-one fast-path offset (/O), end of first page (/E), number
    # of pages (/N), and the hint stream offset (/T) so callers can
    # resolve page 1 without parsing the rest of the file.
    #
    # A non-linearized PDF returns nil from .detect.
    class LinearizationReader
      LinearizationInfo = Struct.new(
        :linearized,    # 1.0 marker
        :file_length,   # /L
        :first_page_obj_offset, # /O
        :first_page_end_offset, # /E
        :page_count, # /N
        :hint_stream_offset, # /T
        :primary_hint_offset, # /H [offset, length]
        keyword_init: true
      )

      class << self
        # Parse the first indirect object at offset 0 in +io+ and
        # return a LinearizationInfo if it's a Linearization dict,
        # nil otherwise.
        def detect(io)
          io.seek(0, IO::SEEK_SET)
          header = io.read(1024).to_s
          return nil unless header.start_with?("%PDF-")

          # Skip the header line, then look for the first "N G obj"
          # marker. The Linearization dict is on the first indirect
          # object in a linearized file.
          io.seek(0, IO::SEEK_SET)
          tok = Pdfrb::Source::Tokenizer.new(io)
          parser = Pdfrb::Source::Parser.new(tok, document: nil)
          first_obj = begin
            parser.parse_indirect_object
          rescue StandardError
            nil
          end
          return nil unless first_obj

          dict = dictionary_value(first_obj)
          return nil unless dict && dict[:Linearized]

          build_info(dict)
        end

        private

        def dictionary_value(obj)
          return obj.value if obj.is_a?(Pdfrb::Model::Cos::Dictionary)
          return obj.value if obj.is_a?(Pdfrb::Model::Cos::Stream)

          obj if obj.is_a?(::Hash)
        end

        def build_info(dict)
          hint = dict[:H]
          LinearizationInfo.new(
            linearized: dict[:Linearized].to_s,
            file_length: dict[:L]&.to_i,
            first_page_obj_offset: dict[:O]&.to_i,
            first_page_end_offset: dict[:E]&.to_i,
            page_count: dict[:N]&.to_i,
            hint_stream_offset: dict[:T]&.to_i,
            primary_hint_offset: hint.is_a?(::Array) ? hint : nil
          )
        end
      end
    end
  end
end
