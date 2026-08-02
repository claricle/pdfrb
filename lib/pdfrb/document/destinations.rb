# frozen_string_literal: true

module Pdfrb
  class Document
    # Named-destinations facade (stub). Full implementation in TODO 129.
    class Destinations
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def [](name)
        names = document.catalog.value[:Names]
        return nil unless names.is_a?(::Hash) || names.is_a?(Pdfrb::Model::Cos::Dictionary)

        dests = names.is_a?(Pdfrb::Model::Cos::Dictionary) ? names.value[:Dests] : names[:Dests]
        dests ? dests[name] : nil
      end
    end
  end
end
