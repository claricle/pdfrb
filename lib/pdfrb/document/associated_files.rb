# frozen_string_literal: true

module Pdfrb
  class Document
    # Associated Files (AF) facade. PDF 2.0 introduced /AF arrays on
    # Catalog, Page, and StructElem to declare the relationship between
    # embedded files and the context they appear in.
    #
    # Relationship types (ISO 32000-2 §7.11.3):
    #   :Source       — source document for the content
    #   :Data         — data file referenced by the content
    #   :Alternative  — alternative representation
    #   :Supplement   — supplemental information
    #   :Unspecified  — relationship not specified
    #
    # App Note 002: https://github.com/pdf-association/appnote-pdf20-002-af
    class AssociatedFiles
      RELATIONSHIP_TYPES = %i[
        Source Data Alternative Supplement Unspecified
        Encrypted Payload FormData Schema Template
      ].freeze

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Associate a filespec with the Catalog-level /AF array.
      # @param filespec_ref [Pdfrb::Model::Reference] the /Filespec ref.
      # @param relationship [Symbol] one of RELATIONSHIP_TYPES.
      def add_to_catalog(filespec_ref, relationship: :Unspecified)
        ensure_relationship(filespec_ref, relationship)
        append_to_af_array(document.catalog, filespec_ref)
      end

      # Associate a filespec with a specific page's /AF array.
      def add_to_page(page, filespec_ref, relationship: :Unspecified)
        ensure_relationship(filespec_ref, relationship)
        append_to_af_array(page, filespec_ref)
      end

      # Associate a filespec with a structure element's /AF array.
      def add_to_element(struct_elem, filespec_ref, relationship: :Unspecified)
        ensure_relationship(filespec_ref, relationship)
        append_to_af_array(struct_elem, filespec_ref)
      end

      # Convenience: create a filespec + embedded file from raw bytes,
      # then associate it at the catalog level.
      # @return [Pdfrb::Model::Reference] the filespec reference.
      def embed(filename:, data:, relationship: :Unspecified,
                description: nil, mime_type: nil)
        filespec = document.files.add(data, name: filename,
                                            description: description,
                                            mime_type: mime_type)
        ref = Pdfrb::Model::Reference.new(filespec.oid, filespec.gen)
        filespec.value[:AFRelationship] = relationship
        add_to_catalog(ref, relationship: relationship)
        ref
      end

      # List all catalog-level AF filespecs.
      def catalog_files
        read_af_array(document.catalog)
      end

      private

      def ensure_relationship(filespec_ref, relationship)
        unless RELATIONSHIP_TYPES.include?(relationship)
          raise ArgumentError, "invalid AF relationship: #{relationship}"
        end

        filespec = document.object(filespec_ref)
        return unless filespec.is_a?(Pdfrb::Model::Cos::Dictionary)

        filespec.value[:AFRelationship] = relationship
      end

      def append_to_af_array(dict_obj, ref)
        af = dict_obj.value[:AF]
        if af.nil?
          dict_obj.value[:AF] = [ref]
        elsif af.is_a?(::Array)
          af << ref
        else
          dict_obj.value[:AF] = [af, ref]
        end
      end

      def read_af_array(dict_obj)
        af = dict_obj.value[:AF]
        return [] unless af

        refs = af.is_a?(::Array) ? af : [af]
        refs.filter_map do |ref|
          obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
          obj if obj.is_a?(Pdfrb::Model::Cos::Dictionary)
        end
      end
    end
  end
end
