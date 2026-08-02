# frozen_string_literal: true

module Pdfrb
  module Arlington
    # One row in an Arlington TSV (one field in a PDF object type).
    #
    # The 12 columns are exposed as typed attributes where possible;
    # predicate-laden values (Required, SpecialCase, SinceVersion with
    # fn:...) preserve their raw text for the predicate evaluator to
    # consume lazily.
    class FieldDefinition
      attr_reader :key, :types_raw, :since_version, :deprecated_in,
                  :required_literal, :indirect_reference, :inheritable,
                  :default_value, :possible_values, :special_case,
                  :link, :note

      def initialize(key:, types_raw:, since_version:, deprecated_in:,
                     required_literal:, indirect_reference:, inheritable:,
                     default_value:, possible_values:, special_case:,
                     link:, note:)
        @key = key
        @types_raw = types_raw
        @since_version = since_version
        @deprecated_in = deprecated_in
        @required_literal = required_literal
        @indirect_reference = indirect_reference
        @inheritable = inheritable
        @default_value = default_value
        @possible_values = possible_values
        @special_case = special_case
        @link = link
        @note = note
        freeze
      end

      # Build a FieldDefinition from a 12-element Array of TSV cells.
      def self.from_row(row)
        raise ArgumentError, "TSV row needs 12 cells" unless row.length == 12

        new(
          key: row[0],
          types_raw: row[1],
          since_version: PdfVersion.from_tsv_cell(row[2]) || PdfVersion.new("1.0"),
          deprecated_in: PdfVersion.from_tsv_cell(row[3]),
          required_literal: parse_required(row[4]),
          indirect_reference: row[5],
          inheritable: parse_boolean(row[6]),
          default_value: row[7]&.then { |s| s.empty? ? nil : s },
          possible_values: row[8]&.then { |s| s.empty? ? nil : s },
          special_case: row[9]&.then { |s| s.empty? ? nil : s },
          link: row[10]&.then { |s| s.empty? ? nil : s },
          note: row[11]
        )
      end

      # The bare type symbols this field allows (predicate-laden types
      # are dropped — caller resolves those via the predicate
      # evaluator if needed).
      def types
        types_raw.split(";").filter_map do |raw|
          stripped = raw.strip
          stripped.to_sym if Type.valid?(stripped.to_sym)
        end
      end

      def array?
        types.include?(:array)
      end

      def dictionary?
        types.include?(:dictionary)
      end

      def stream?
        types.include?(:stream)
      end

      def name?
        types.include?(:name)
      end

      def required?
        required_literal == true
      end

      def required_predicate?
        required_literal.is_a?(::String) && required_literal.start_with?("fn:")
      end

      def inheritable?
        inheritable == true
      end

      def links
        return [] if link.nil?

        link.scan(/\[([^\[\]]+)\]/).flatten.map { |l| l.split(",").map(&:strip) }.flatten
      end

      def possible_value_list
        return [] if possible_values.nil?

        possible_values.scan(/\[([^\[\]]+)\]/).flatten.flat_map do |l|
          l.split(",").map(&:strip)
        end
      end

      class << self
        private

        def parse_required(cell)
          return true if cell == "TRUE"
          return false if cell == "FALSE"
          return nil if cell.nil? || cell.empty?

          cell
        end

        def parse_boolean(cell)
          return true if cell == "TRUE"
          return false if cell == "FALSE"

          nil
        end
      end
    end
  end
end
