# frozen_string_literal: true

begin; require "lutaml/model"; rescue LoadError; end

module Pdfrb
  module XMP
    module Schemas
      # Namespace definitions for XMP schemas.
      class DublinCoreNS < Lutaml::Xml::Namespace
        uri "http://purl.org/dc/elements/1.1/"
        prefix_default "dc"
      end

      class PdfNS < Lutaml::Xml::Namespace
        uri "http://ns.adobe.com/pdf/1.3/"
        prefix_default "pdf"
      end

      class XmpNS < Lutaml::Xml::Namespace
        uri "http://ns.adobe.com/xap/1.0/"
        prefix_default "xmp"
      end

      class XmpRightsNS < Lutaml::Xml::Namespace
        uri "http://ns.adobe.com/xap/1.0/rights/"
        prefix_default "xmpRights"
      end

      # Dublin Core (dc:) — basic descriptive metadata.
      class DublinCore < Lutaml::Model::Serializable
        attribute :title, :string, collection: true
        attribute :creator, :string, collection: true
        attribute :description, :string, collection: true
        attribute :subject, :string, collection: true
        attribute :identifier, :string, collection: true
        attribute :language, :string, collection: true

        xml do
          root "dc"
          namespace DublinCoreNS
          map_element "title", to: :title
          map_element "creator", to: :creator
          map_element "description", to: :description
          map_element "subject", to: :subject
          map_element "identifier", to: :identifier
          map_element "language", to: :language
        end
      end

      # PDF (pdf:) — PDF-specific metadata.
      class PDF < Lutaml::Model::Serializable
        attribute :keywords, :string
        attribute :producer, :string
        attribute :trapped, :string

        xml do
          root "pdf"
          namespace PdfNS
          map_element "Keywords", to: :keywords
          map_element "Producer", to: :producer
          map_element "Trapped", to: :trapped
        end
      end

      # XMP basic (xmp:) — document lifecycle metadata.
      class XMPBasic < Lutaml::Model::Serializable
        attribute :creator_tool, :string
        attribute :create_date, :string
        attribute :modify_date, :string
        attribute :metadata_date, :string

        xml do
          root "xmp"
          namespace XmpNS
          map_element "CreatorTool", to: :creator_tool
          map_element "CreateDate", to: :create_date
          map_element "ModifyDate", to: :modify_date
          map_element "MetadataDate", to: :metadata_date
        end
      end

      # XMP Rights (xmpRights:) — rights management metadata.
      class XMPRights < Lutaml::Model::Serializable
        attribute :marked, :boolean
        attribute :web_statement, :string

        xml do
          root "xmpRights"
          namespace XmpRightsNS
          map_element "Marked", to: :marked
          map_element "WebStatement", to: :web_statement
        end
      end
    end
  end
end
