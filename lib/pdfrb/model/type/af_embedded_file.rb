# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PDF 2.0 Associated-File embedded stream (App Note 002).
      class AFEmbeddedFile < EmbeddedFile
        arlington_object "AFEmbeddedFileStream"
      end
    end
  end
end
