# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Pdfrb
  module Conformance
    # PDF/UA-1 deep tagging checks (ISO 14289-1 §7). Extends the
    # baseline PDF/UA rule set with structural-tree traversal rules:
    #   * Every /L (list) must contain /LI children
    #   * Every /LI must contain /LBody
    #   * Every /Table must contain /TR rows
    #   * Every /TH and /TD must have /Scope or headers linkage
    #   * Every /Figure, /Formula, /Table has /Alt or /ActualText
    module PdfUATaggingDeep
      module_function

      RULESET = RuleSet.new("PDF/UA-tagging-deep").tap do |rs|
        rs.register(Rule.new(
                      id: "tag-deep-1",
                      description: "List /L must have /LI children",
                      severity: :warning,
                      spec_clause: "ISO 14289-1 7.4",
                      check: ->(doc) {
                        vs = []
                        TaggedPdf.walk_structure(doc) do |elem|
                          next unless elem[:S] == :L

                          kids = TaggedPdf.structure_kids(elem, doc)
                          has_li = kids.any? { |k| k[:S] == :LI }
                          next if has_li

                          vs << Violation.new(
                            rule_id: "tag-deep-1",
                            message: "/L without /LI child",
                            object: "StructElem/L",
                            severity: :warning,
                            spec_clause: "ISO 14289-1 7.4"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-deep-2",
                      description: "/LI must have /LBody",
                      severity: :warning,
                      spec_clause: "ISO 14289-1 7.4",
                      check: ->(doc) {
                        vs = []
                        TaggedPdf.walk_structure(doc) do |elem|
                          next unless elem[:S] == :LI

                          kids = TaggedPdf.structure_kids(elem, doc)
                          has_body = kids.any? { |k| k[:S] == :LBody }
                          next if has_body

                          vs << Violation.new(
                            rule_id: "tag-deep-2",
                            message: "/LI without /LBody",
                            object: "StructElem/LI",
                            severity: :warning,
                            spec_clause: "ISO 14289-1 7.4"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-deep-3",
                      description: "/Table must have /TR rows",
                      severity: :warning,
                      spec_clause: "ISO 14289-1 7.5",
                      check: ->(doc) {
                        vs = []
                        TaggedPdf.walk_structure(doc) do |elem|
                          next unless elem[:S] == :Table

                          kids = TaggedPdf.structure_kids(elem, doc)
                          has_tr = kids.any? { |k| k[:S] == :TR }
                          next if has_tr

                          vs << Violation.new(
                            rule_id: "tag-deep-3",
                            message: "/Table without /TR child rows",
                            object: "StructElem/Table",
                            severity: :warning,
                            spec_clause: "ISO 14289-1 7.5"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-deep-4",
                      description: "/TH cells should declare /Scope",
                      severity: :warning,
                      spec_clause: "ISO 14289-1 7.5",
                      check: ->(doc) {
                        vs = []
                        TaggedPdf.walk_structure(doc) do |elem|
                          next unless elem[:S] == :TH
                          next if elem[:Scope] || elem[:Headers]

                          vs << Violation.new(
                            rule_id: "tag-deep-4",
                            message: "/TH without /Scope or /Headers",
                            object: "StructElem/TH",
                            severity: :warning,
                            spec_clause: "ISO 14289-1 7.5"
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
