# frozen_string_literal: true

module Pdfrb
  # Pre-write document validation. Checks structural integrity before
  # serialization to prevent producing corrupt PDFs. Raises
  # Pdfrb::ValidationError with a descriptive message.
  module Validator
    class << self
      # Validate a document before writing. Returns true if valid,
      # raises Pdfrb::ValidationError otherwise.
      # @param document [Pdfrb::Document]
      # @return [true]
      def validate!(document)
        errors = validate(document)
        return true if errors.empty?

        raise Pdfrb::ValidationError, errors.join("; ")
      end

      # Validate without raising. Returns array of error strings.
      # @return [Array<String>]
      def validate(document)
        errors = []
        check_catalog(document, errors)
        check_pages(document, errors)
        check_references(document, errors)
        errors
      end

      private

      def check_catalog(document, errors)
        catalog = document.catalog
        if catalog.nil?
          errors << "Document has no Catalog"
          return
        end

        errors << "Catalog has no /Pages" unless catalog.value[:Pages]
      end

      def check_pages(document, errors)
        count = 0
        document.pages.each do |page|
          count += 1
          unless page.value[:MediaBox]
            errors << "Page #{page.oid} has no /MediaBox"
          end
        end

        errors << "Document has no pages" if count.zero?
      end

      def check_references(document, errors)
        resolved = Set.new
        document.each_indirect_object { |obj| resolved << obj.oid }

        dangling = []
        document.each_indirect_object do |obj|
          walk_refs(obj.value) do |ref|
            unless resolved.include?(ref.oid)
              dangling << "object #{obj.oid} references #{ref.oid} #{ref.gen} R (unresolved)"
            end
          end
        end

        errors.concat(dangling.uniq.first(10))
      end

      def walk_refs(value, &block)
        case value
        when ::Hash
          value.each_value { |v| walk_refs(v, &block) }
        when ::Array, Pdfrb::Model::PdfArray
          value.each { |v| walk_refs(v, &block) }
        when Pdfrb::Model::Reference
          yield value
        end
      end
    end
  end
end

require "set"
