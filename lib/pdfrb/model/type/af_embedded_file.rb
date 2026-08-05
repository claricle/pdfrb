# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PDF 2.0 Associated-File embedded stream (App Note 002).
      class AFEmbeddedFile < EmbeddedFile
        arlington_object "AFEmbeddedFileStream"

        def af_relationship
          return nil unless params

          obj = params.is_a?(Pdfrb::Model::Reference) && document ? document.object(params) : params
          obj && obj[:AFRelationship]
        end

        def associated_file_relationship?
          !!af_relationship
        end
      end
    end
  end
end
