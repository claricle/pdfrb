# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Embedded file stream (s7.11.3). The actual payload of a
      # /Filespec /EF entry.
      class EmbeddedFile < Pdfrb::Model::Cos::Stream
        arlington_object "EmbeddedFileStream"
      end
    end
  end
end
