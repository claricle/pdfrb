# frozen_string_literal: true

module Pdfrb
  module Arlington
    # One TSV file = one PDF object type definition. Holds the list
    # of FieldDefinitions and provides lookup by key (with wildcard
    # support for map-style objects).
    class ObjectDefinition
      attr_reader :name, :version, :fields

      def initialize(name:, version: "latest", fields: [])
        @name = name
        @version = version
        @fields = fields
        freeze
      end

      def self.from_tsv(rows, name:, version:)
        fields = rows.map { |row| FieldDefinition.from_row(row) }
        new(name: name, version: version, fields: fields)
      end

      def each_field(&)
        @fields.each(&)
      end

      def field_for(key)
        @fields.find { |f| f.key == key.to_s }
      end
      alias [] field_for

      def keys
        @fields.map(&:key)
      end

      def has_wildcard?
        @fields.any? { |f| f.key == "*" }
      end

      def map?
        @fields.first&.key == "*"
      end
    end
  end
end
