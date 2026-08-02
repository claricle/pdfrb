# frozen_string_literal: true

module Pdfrb
  class Document
    # Attached-files facade (stub). Full implementation lands in TODO 128.
    class Files
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def add(_io, name:, **_opts)
        raise NotImplementedError,
              "File embedding lands in TODO 128 (per App Note 002 — Associated Files)"
      end

      def each
        return enum_for(:each) unless block_given?

        names_tree = document.catalog.value.dig(:Names, :EmbeddedFiles)
        return self unless names_tree
        # Real implementation walks the name-tree.
        self
      end
    end
  end
end
