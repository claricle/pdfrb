# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # File trailer dict (s7.5.5). Root of the cross-reference chain.
      # Fields: /Size, /Prev, /Root, /Encrypt, /Info, /ID, /XRefStm,
      # /AuthCode, /AdditionalStreams, /DocChecksum.
      class FileTrailer < Pdfrb::Model::Cos::Dictionary
        arlington_object "FileTrailer"
      end
    end
  end
end
