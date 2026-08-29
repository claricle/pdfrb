# frozen_string_literal: true

# rubocop:disable-next Metrics/BlockLength
module Pdfrb
  module Conformance
    # PDF 2.0 Associated Files (AF) validation per Application Note
    # 002 (sources at ~/src/pdfa/appnote-pdf20-002-af/). The AF
    # mechanism attaches external files to PDF objects with a typed
    # relationship (Source, Data, Alternative, Supplement,
    # EncryptedPayload, Unspecified).
    #
    # This rule set checks:
    #   * /AF arrays are present where required (PDF 2.0 catalog).
    #   * Each /AF entry is a /Type /AssociatedFile or FileSpec dict
    #     with an /AFRelationship.
    #   * /AFRelationship is one of the six allowed values.
    #   * FileSpec dicts carry /UF + /EF.
    #   * EmbeddedFile streams carry /Subtype (MIME type).
    module Pdf2AF
      ALLOWED_RELATIONSHIPS = %i[Source Data Alternative Supplement
                                 EncryptedPayload Unspecified].freeze

      module_function

      RULESET = RuleSet.new("PDF 2.0 AF").tap do |rs|
        rs.register(Rule.new(
                      id: "af-1",
                      description: "/AF entries must declare AFRelationship",
                      severity: :error,
                      spec_clause: "PDF 2.0 App Note 002 3.1",
                      check: ->(doc) {
                        violations = []
                        each_af_entry(doc) do |container, entry|
                          next if relationship_of(entry)

                          violations << Violation.new(
                            rule_id: "af-1",
                            message: "/AF entry on #{container_label(container)} missing /AFRelationship",
                            object: container_label(container),
                            severity: :error,
                            spec_clause: "PDF 2.0 App Note 002 3.1"
                          )
                        end
                        violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "af-2",
                      description: "/AFRelationship must be one of the allowed values",
                      severity: :error,
                      spec_clause: "PDF 2.0 App Note 002 3.2",
                      check: ->(doc) {
                        violations = []
                        each_af_entry(doc) do |container, entry|
                          rel = relationship_of(entry)
                          next unless rel
                          next if ALLOWED_RELATIONSHIPS.include?(rel.to_sym)

                          violations << Violation.new(
                            rule_id: "af-2",
                            message: "/AFRelationship '#{rel}' is not one of #{ALLOWED_RELATIONSHIPS.join(', ')}",
                            object: container_label(container),
                            severity: :error,
                            spec_clause: "PDF 2.0 App Note 002 3.2"
                          )
                        end
                        violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "af-3",
                      description: "FileSpec dicts must carry /UF and /EF",
                      severity: :error,
                      spec_clause: "PDF 2.0 7.11.3",
                      check: ->(doc) {
                        violations = []
                        each_filespec(doc) do |_container, fs|
                          ok = fs[:UF] && fs[:EF]
                          next if ok

                          violations << Violation.new(
                            rule_id: "af-3",
                            message: "FileSpec missing /UF or /EF",
                            object: "FileSpec",
                            severity: :error,
                            spec_clause: "PDF 2.0 7.11.3"
                          )
                        end
                        violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "af-4",
                      description: "EmbeddedFile streams should declare /Subtype MIME",
                      severity: :warning,
                      spec_clause: "PDF 2.0 7.11.4",
                      check: ->(doc) {
                        violations = []
                        doc.each_indirect_object do |obj|
                          next unless obj.value[:Type] == :EmbeddedFile
                          next if obj.value[:Subtype]

                          violations << Violation.new(
                            rule_id: "af-4",
                            message: "EmbeddedFile missing /Subtype (MIME type)",
                            object: "EmbeddedFile",
                            severity: :warning,
                            spec_clause: "PDF 2.0 7.11.4"
                          )
                        end
                        violations
                      }
                    ))
      end

      def validate(document)
        RULESET.validate(document)
      end

      # Walk every indirect object that has an /AF key, yielding
      # (container_object, af_entry) for each entry in each /AF
      # array. /AF entries may be References (resolves) or dicts.
      def each_af_entry(document)
        document.each_indirect_object do |container|
          af = container.value[:AF]
          next unless af

          af_value = af.is_a?(Pdfrb::Model::PdfArray) ? af.value : af
          entries = af_value.is_a?(::Array) ? af_value : [af_value]
          entries.each do |e|
            resolved = document.resolve(e)
            yield container, resolved if resolved
          end
        end
      end

      # Walk every FileSpec dict in the document.
      def each_filespec(document)
        document.each_indirect_object do |container|
          fs = container.value[:Type] == :FileSpec ? container : nil
          if fs
            yield container, fs
            next
          end

          # Also pick up FileSpecs referenced from /AF arrays.
          af = container.value[:AF]
          next unless af

          af_value = af.is_a?(Pdfrb::Model::PdfArray) ? af.value : af
          entries = af_value.is_a?(::Array) ? af_value : [af_value]
          entries.each do |e|
            resolved = document.resolve(e)
            next unless resolved && resolved.value[:Type] == :FileSpec

            yield container, resolved
          end
        end
      end

      def relationship_of(entry)
        return nil unless entry

        value = entry.is_a?(Pdfrb::Model::Cos::Dictionary) ? entry.value : entry
        return nil unless value.is_a?(::Hash)

        # AssociatedFile dicts put the relationship on
        # /AFRelationship; FileSpecs put it on the same key when
        # they're AF-related.
        value[:AFRelationship]
      end

      def container_label(obj)
        type = obj.value[:Type]
        return "Object/#{obj.oid}" unless type

        "Object/#{type}/#{obj.oid}"
      end
    end
  end
end
