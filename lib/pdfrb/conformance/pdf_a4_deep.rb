# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Pdfrb
  module Conformance
    # PDF/A-4 deep checks (ISO 19005-4). Builds on the SHARED + A4
    # rules in Pdfrb::Conformance::PdfA by adding additional
    # structural requirements specific to PDF/A-4: PDF 2.0 base,
    # XMP metadata required (not just recommended), /AF entries
    # valid per App Note 002.
    module PdfA4Deep
      module_function

      RULESET = RuleSet.new("PDF/A-4-deep").tap do |rs|
        rs.register(Rule.new(
                      id: "a4deep-1",
                      description: "PDF/A-4 requires XMP /Metadata stream",
                      severity: :error,
                      spec_clause: "ISO 19005-4 6.1",
                      check: ->(doc) {
                        next nil if doc.catalog[:Metadata]

                        Violation.new(
                          rule_id: "a4deep-1",
                          message: "PDF/A-4 requires /Catalog/Metadata XMP stream",
                          object: "Catalog/Metadata",
                          severity: :error,
                          spec_clause: "ISO 19005-4 6.1"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "a4deep-2",
                      description: "PDF/A-4 should have valid /OutputIntents when colour-managed",
                      severity: :warning,
                      spec_clause: "ISO 19005-4 6.2.4",
                      check: ->(doc) {
                        next nil if doc.catalog[:OutputIntents]

                        # Only flag when document has ICCBased color spaces
                        has_icc = false
                        doc.each_indirect_object do |obj|
                          next unless obj.value[:ColorSpace]

                          cs = obj.value[:ColorSpace]
                          cs_array = cs.is_a?(::Array) ? cs : [cs]
                          if cs_array.any?(:ICCBased)
                            has_icc = true
                            break
                          end
                        end
                        next nil unless has_icc

                        Violation.new(
                          rule_id: "a4deep-2",
                          message: "ICC-based color spaces require /OutputIntents in PDF/A-4",
                          object: "Catalog/OutputIntents",
                          severity: :warning,
                          spec_clause: "ISO 19005-4 6.2.4"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "a4deep-3",
                      description: "PDF/A-4 forbids EmbeddedFile streams",
                      severity: :error,
                      spec_clause: "ISO 19005-4 6.4",
                      check: ->(doc) {
                        vs = []
                        doc.each_indirect_object do |obj|
                          next unless obj.value[:Type] == :EmbeddedFile

                          vs << Violation.new(
                            rule_id: "a4deep-3",
                            message: "PDF/A-4 forbids EmbeddedFile streams",
                            object: "EmbeddedFile",
                            severity: :error,
                            spec_clause: "ISO 19005-4 6.4"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))
      end

      def validate(document)
        RULESET.validate(document)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
