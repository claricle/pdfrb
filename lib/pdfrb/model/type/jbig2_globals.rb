# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # JBIG2 Globals stream (s7.4.7). Holds shared JBIG2 segment
      # data referenced by /DecodeParms /JBIG2Globals.
      class JBIG2Globals < Pdfrb::Model::Cos::Stream
        def globals_data
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
