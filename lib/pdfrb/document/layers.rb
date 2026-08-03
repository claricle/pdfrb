# frozen_string_literal: true

module Pdfrb
  class Document
    # Facade for Optional Content Groups (layers). OCGs let authors
    # mark content as belonging to a named layer that can be toggled
    # on/off by the viewer (ISO 32000-2 §8.11).
    #
    # Each layer is a /Type /OCG dictionary with a /Name. The
    # Catalog gets an /OCProperties entry:
    #   /OCGs — array of all OCG indirect refs.
    #   /D — default viewing config:
    #     /BaseState /ON, /OFF [list of off-by-default OCGs], etc.
    class Layers
      attr_reader :document, :groups

      def initialize(document)
        @document = document
        @groups = []
      end

      # Add a named layer. @return [Pdfrb::Model::Cos::Dictionary] the OCG.
      def add(name, default_on: true)
        ensure_oc_properties
        ocg = document.add(
          { Type: :OCG, Name: name },
          type: Pdfrb::Model::Cos::Dictionary
        )
        ref = Pdfrb::Model::Reference.new(ocg.oid, ocg.gen)
        @groups << { ref: ref, ocg: ocg, default_on: default_on }
        ocg
      end

      # Write /OCProperties to the Catalog. Called automatically by #add
      # but can be called again to refresh after external modifications.
      def sync!
        return if @groups.empty?

        ocgs_array = @groups.map { |g| g[:ref] }
        off_array = @groups.reject { |g| g[:default_on] }.map { |g| g[:ref] }

        default_config = { BaseState: :ON }
        default_config[:OFF] = off_array unless off_array.empty?

        catalog = document.catalog
        catalog.value[:OCProperties] = {
          OCGs: ocgs_array,
          D: default_config,
        }
      end

      private

      def ensure_oc_properties
        catalog = document.catalog
        return if catalog.value[:OCProperties]

        catalog.value[:OCProperties] = { OCGs: [], D: { BaseState: :ON } }
      end
    end
  end
end
