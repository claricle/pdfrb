# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PDF 2.0 Associated-File FileSpec (App Note 002). Adds
      # /AFRelationship to the base FileSpec.
      class AFFileSpecification < FileSpecification
        arlington_object "AFFileSpecification"

        def af_relationship; self[:AFRelationship]; end

        def source?
          af_relationship&.to_sym == :Source
        end

        def data?
          af_relationship&.to_sym == :Data
        end

        def alternative?
          af_relationship&.to_sym == :Alternative
        end

        def supplement?
          af_relationship&.to_sym == :Supplement
        end

        def encrypted?
          af_relationship&.to_sym == :EncryptedPayload
        end

        def form_fillin?
          af_relationship&.to_sym == :FormData
        end

        def schema?
          af_relationship&.to_sym == :Schema
        end

        def unspecified?
          af_relationship.nil? || af_relationship&.to_sym == :Unspecified
        end
      end
    end
  end
end
