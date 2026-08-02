# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PDF 2.0 Associated-File FileSpec (App Note 002). Adds
      # /AFRelationship to the base FileSpec.
      class AFFileSpecification < FileSpecification
        arlington_object "AFFileSpecification"
      end
    end
  end
end
