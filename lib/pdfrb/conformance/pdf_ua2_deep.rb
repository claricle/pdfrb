# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Pdfrb
  module Conformance
    # PDF/UA-2 (ISO 14289-2) deep checks. PDF/UA-2 is rooted in
    # PDF 2.0 and adds stricter requirements on top of PDF/UA-1:
    #   * PDF version >= 2.0
    #   * Structure tree with consistent /RoleMap
    #   * Heading hierarchy (H1-H6) without skipping levels
    #   * Every Figure, Formula, Table has /Alt or /ActualText
    module PdfUA2Deep
      module_function

      RULESET = RuleSet.new("PDF/UA-2-deep").tap do |rs|
        rs.register(Rule.new(
                      id: "ua2-1",
                      description: "PDF/UA-2 requires PDF 2.0",
                      severity: :error,
                      spec_clause: "ISO 14289-2 4.1",
                      check: ->(doc) {
                        v = doc.version.to_s
                        next nil if v >= "2.0"

                        Violation.new(
                          rule_id: "ua2-1",
                          message: "PDF/UA-2 requires PDF 2.0 (was #{v})",
                          object: "Header",
                          severity: :error,
                          spec_clause: "ISO 14289-2 4.1"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "ua2-2",
                      description: "Heading hierarchy must not skip levels",
                      severity: :warning,
                      spec_clause: "ISO 14289-2 7.3",
                      check: ->(doc) {
                        vs = []
                        prev_level = 0
                        TaggedPdf.walk_structure(doc) do |elem|
                          s = elem[:S]&.to_s
                          next unless s&.match?(/\AH([1-6])\z/)

                          level = Regexp.last_match(1).to_i
                          if level > prev_level + 1 && prev_level.positive?
                            vs << Violation.new(
                              rule_id: "ua2-2",
                              message: "Heading H#{level} jumps from H#{prev_level}",
                              object: "StructElem/#{s}",
                              severity: :warning,
                              spec_clause: "ISO 14289-2 7.3"
                            )
                          end
                          prev_level = level
                        end
                        vs.empty? ? nil : vs
                      }
                    ))

        rs.register(Rule.new(
                      id: "ua2-3",
                      description: "Formula elements require /Alt or /ActualText",
                      severity: :warning,
                      spec_clause: "ISO 14289-2 7.9",
                      check: ->(doc) {
                        vs = []
                        TaggedPdf.walk_structure(doc) do |elem|
                          next unless elem[:S] == :Formula
                          next if elem[:Alt] || elem[:ActualText]

                          vs << Violation.new(
                            rule_id: "ua2-3",
                            message: "Formula without /Alt or /ActualText",
                            object: "StructElem/Formula",
                            severity: :warning,
                            spec_clause: "ISO 14289-2 7.9"
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
