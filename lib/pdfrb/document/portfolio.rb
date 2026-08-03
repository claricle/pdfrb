# frozen_string_literal: true

module Pdfrb
  class Document
    # PDF Portfolio facade. A portfolio is a PDF with a /Collection
    # dictionary on the Catalog that provides a collection view of
    # embedded files (ISO 32000-2 §12.3.5).
    #
    # Inspired by mn2pdf's PDFPortfolio (which uses PDFBox). Provides
    # field schema, default view configuration, and per-item metadata.
    class Portfolio
      Field = Struct.new(:name, :type, :subtype, :order, keyword_init: true) do
        def pdf_hash
          h = { N: name, T: type }
          h[:FT] = type unless type == :text
          h[:Subtype] = subtype if subtype
          h[:O] = order if order
          h
        end
      end

      Item = Struct.new(:name, :file_bytes, :mime_type,
                        :description, :fields, keyword_init: true)

      DEFAULT_FIELDS = [
        { name: "Name", type: :text }.freeze,
        { name: "Description", type: :text, subtype: :Description }.freeze,
        { name: "Size", type: :number }.freeze,
        { name: "Modified", type: :date, subtype: :CreationDate }.freeze,
      ].freeze

      attr_reader :document, :items, :schema_fields

      def initialize(document)
        @document = document
        @items = []
        @schema_fields = DEFAULT_FIELDS.map { |f| Field.new(**f) }
      end

      # Add a schema field. Order matters for display.
      def add_field(name, type: :text, subtype: nil, order: nil)
        @schema_fields << Field.new(
          name: name,
          type: type,
          subtype: subtype,
          order: order || @schema_fields.length
        )
      end

      # Add an item (embedded file) to the portfolio.
      def add_item(name, file_bytes, mime_type: nil,
                   description: nil, fields: {})
        @items << Item.new(
          name: name,
          file_bytes: file_bytes,
          mime_type: mime_type,
          description: description,
          fields: fields
        )
      end

      # Commit the portfolio configuration to the document.
      # Sets /Collection on the Catalog, creates /Filespec for each item,
      # and embeds the file data via /EF.
      def commit!
        catalog = document.catalog
        catalog.value[:Collection] = collection_dict
      end

      private

      def collection_dict
        {
          Type: :Collection,
          Schema: schema_fields.map(&:pdf_hash),
          D: {
            View: :D,
            Hide: false,
            Order: @schema_fields.map(&:name),
          },
          Items: items_references,
        }
      end

      def items_references
        @items.map do |item|
          filespec = document.add(
            {
              Type: :Filespec,
              F: item.name,
              UF: item.name,
              Desc: item.description,
            }.compact,
            type: Pdfrb::Model::Cos::Dictionary
          )
          ef = document.add(
            {
              F: embedded_file_ref(item),
              UF: embedded_file_ref(item),
            },
            type: Pdfrb::Model::Cos::Dictionary
          )
          filespec.value[:EF] = Pdfrb::Model::Reference.new(ef.oid, ef.gen)
          filespec.value[:AFRelationship] = :Unspecified
          Pdfrb::Model::Reference.new(filespec.oid, filespec.gen)
        end
      end

      def embedded_file_ref(item)
        embedded = document.add(
          { Type: :EmbeddedFile, Length: item.file_bytes.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        embedded.stream = item.file_bytes
        Pdfrb::Model::Reference.new(embedded.oid, embedded.gen)
      end
    end
  end
end
