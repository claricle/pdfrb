# frozen_string_literal: true

# rubocop:disable-next Metrics/BlockLength
module Pdfrb
  module Conformance
    # Tagged PDF validation per ISO 32000-1 §14.8 (and ISO 32000-2
    # §14.8). Tagged PDF is the foundation of PDF/UA and PDF/A-2a/3a;
    # this rule set checks the structural requirements that any
    # tagged PDF must satisfy, regardless of higher-level profile.
    #
    # This is intentionally a subset of PDF/UA. Use PdfUA for the
    # full accessibility profile; use TaggedPdf for a baseline
    # structural pass that doesn't require accessibility annotations
    # (alt text, reading order).
    module TaggedPdf
      STANDARD_STRUCTURE_TYPES = %i[
        Document Part Div Art Sect BlockQuote Caption TOC TOCI
        Index NonStruct Private H H1 H2 H3 H4 H5 H6 P L LI Lbl LBody
        Table TR TH TD THead TBody TFoot Caption Span Quote Note
        Reference BibEntry Code Figure Formula Form
      ].freeze

      module_function

      RULESET = RuleSet.new("TaggedPDF").tap do |rs|
        rs.register(Rule.new(
                      id: "tag-1",
                      description: "/MarkInfo /Marked must be true",
                      severity: :error,
                      spec_clause: "ISO 32000-2 14.8.1",
                      check: ->(doc) {
                        mark_info = doc.catalog[:MarkInfo]
                        mark_info = doc.object(mark_info) if mark_info.is_a?(Pdfrb::Model::Reference)
                        next nil if mark_info && mark_info[:Marked] == true

                        Violation.new(
                          rule_id: "tag-1",
                          message: "/MarkInfo /Marked true is required for tagged PDF",
                          object: "Catalog",
                          severity: :error,
                          spec_clause: "ISO 32000-2 14.8.1"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-2",
                      description: "/StructTreeRoot must be present",
                      severity: :error,
                      spec_clause: "ISO 32000-2 14.7.2",
                      check: ->(doc) {
                        next nil if doc.catalog[:StructTreeRoot]

                        Violation.new(
                          rule_id: "tag-2",
                          message: "/StructTreeRoot required for tagged PDF",
                          object: "Catalog",
                          severity: :error,
                          spec_clause: "ISO 32000-2 14.7.2"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-3",
                      description: "Structure elements must use standard types",
                      severity: :warning,
                      spec_clause: "ISO 32000-2 14.8.4",
                      check: ->(doc) {
                        violations = []
                        walk_structure(doc) do |elem|
                          s = elem[:S]
                          next if s.nil? || STANDARD_STRUCTURE_TYPES.include?(s.to_sym)

                          violations << Violation.new(
                            rule_id: "tag-3",
                            message: "Non-standard structure type '#{s}' on element",
                            object: "StructElem",
                            severity: :warning,
                            spec_clause: "ISO 32000-2 14.8.4"
                          )
                        end
                        violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-4",
                      description: "Figure elements should have /Alt or /ActualText",
                      severity: :warning,
                      spec_clause: "ISO 32000-2 14.9.2",
                      check: ->(doc) {
                        violations = []
                        walk_structure(doc) do |elem|
                          next unless elem[:S] == :Figure
                          next if elem[:Alt] || elem[:ActualText]

                          violations << Violation.new(
                            rule_id: "tag-4",
                            message: "Figure without /Alt or /ActualText",
                            object: "StructElem/Figure",
                            severity: :warning,
                            spec_clause: "ISO 32000-2 14.9.2"
                          )
                        end
                        violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "tag-5",
                      description: "Table structure should include rows",
                      severity: :warning,
                      spec_clause: "ISO 32000-2 14.8.5",
                      check: ->(doc) {
                        violations = []
                        walk_structure(doc) do |elem|
                          next unless elem[:S] == :Table

                          kids = structure_kids(elem, doc)
                          has_tr = kids.any? { |k| k[:S] == :TR }
                          next if has_tr

                          violations << Violation.new(
                            rule_id: "tag-5",
                            message: "Table has no TR child rows",
                            object: "StructElem/Table",
                            severity: :warning,
                            spec_clause: "ISO 32000-2 14.8.5"
                          )
                        end
                        violations
                      }
                    ))
      end

      def validate(document)
        RULESET.validate(document)
      end

      # Walk the structure tree starting at /StructTreeRoot, yielding
      # each element dict. Silently skips cycles and missing refs.
      def walk_structure(document)
        seen = ::Set.new
        root_ref = document.catalog[:StructTreeRoot]
        return unless root_ref

        root = document.resolve(root_ref)
        return unless root

        first_kids = structure_kids(root, document)
        queue = first_kids.dup
        until queue.empty?
          elem = queue.shift
          next unless elem
          next if seen.include?(elem.object_id)

          seen << elem.object_id
          yield elem
          queue.concat(structure_kids(elem, document))
        end
      end

      def structure_kids(element, document)
        kids = element[:K]
        return [] unless kids

        kids = kids.value if kids.is_a?(Pdfrb::Model::PdfArray)
        kids = [kids] unless kids.is_a?(::Array)
        kids.filter_map do |k|
          next nil unless k.is_a?(Pdfrb::Model::Reference)

          obj = document.object(k)
          next nil unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)

          obj
        end
      end
    end
  end
end
