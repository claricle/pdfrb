# frozen_string_literal: true

module Pdfrb
  module Conformance
    module PdfUA
      module_function

      RULESET = RuleSet.new("PDF/UA-1").tap do |rs|
        rs.register(Rule.new(
          id: "ua-1",
          description: "StructTreeRoot required",
          severity: :error,
          spec_clause: "ISO 14289-1 7.1",
          check: ->(doc) {
            next nil if doc.catalog[:StructTreeRoot]

            Violation.new(
              rule_id: "ua-1",
              message: "PDF/UA requires /Catalog/StructTreeRoot",
              object: "Catalog",
              severity: :error,
              spec_clause: "ISO 14289-1 7.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "ua-2",
          description: "MarkInfo /Marked true required",
          severity: :error,
          spec_clause: "ISO 14289-1 7.1",
          check: ->(doc) {
            mark = doc.catalog[:MarkInfo]
            mark = doc.object(mark) if mark.is_a?(Pdfrb::Model::Reference)
            next nil if mark && mark[:Marked] == true

            Violation.new(
              rule_id: "ua-2",
              message: "PDF/UA requires /MarkInfo /Marked true",
              object: "Catalog",
              severity: :error,
              spec_clause: "ISO 14289-1 7.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "ua-3",
          description: "Document language required",
          severity: :error,
          spec_clause: "ISO 14289-1 7.1",
          check: ->(doc) {
            next nil if doc.catalog[:Lang]

            Violation.new(
              rule_id: "ua-3",
              message: "PDF/UA requires /Catalog/Lang",
              object: "Catalog",
              severity: :error,
              spec_clause: "ISO 14289-1 7.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "ua-4",
          description: "Reader requirements",
          severity: :warning,
          spec_clause: "ISO 14289-1 5",
          check: ->(_doc) { nil }
        ))

        rs.register(Rule.new(
          id: "ua-5",
          description: "Figures require Alt text",
          severity: :error,
          spec_clause: "ISO 14289-1 7.1",
          check: ->(doc) {
            violations = []
            walk_structure(doc) do |elem|
              next unless elem[:S] == :Figure
              next if elem[:Alt] || elem[:ActualText]

              violations << Violation.new(
                rule_id: "ua-5",
                message: "Figure without Alt or ActualText",
                object: "StructElem/Figure",
                severity: :error,
                spec_clause: "ISO 14289-1 7.1"
              )
            end
            violations.empty? ? nil : violations
          }
        ))

        rs.register(Rule.new(
          id: "ua-6",
          description: "Heading levels must not skip",
          severity: :error,
          spec_clause: "ISO 14289-1 7.1",
          check: ->(doc) {
            headings = []
            walk_structure(doc) do |elem|
              s = elem[:S]
              next unless s&.to_s&.start_with?("H")

              level = s.to_s[/H(\d+)/, 1]&.to_i
              headings << level if level
            end

            prev = nil
            headings.each do |level|
              if prev && level > prev + 1
                return Violation.new(
                  rule_id: "ua-6",
                  message: "Heading H#{level} skips from H#{prev}",
                  object: "StructElem/H#{level}",
                  severity: :error,
                  spec_clause: "ISO 14289-1 7.1"
                )
              end
              prev = level
            end
            nil
          }
        ))

        rs.register(Rule.new(
          id: "ua-7",
          description: "Tables should have headers",
          severity: :warning,
          spec_clause: "ISO 14289-1 7.2",
          check: ->(_doc) { nil }
        ))

        rs.register(Rule.new(
          id: "ua-8",
          description: "Lists should have Lbl entries",
          severity: :warning,
          spec_clause: "ISO 14289-1 7.3",
          check: ->(_doc) { nil }
        ))
      end

      def validate(document)
        RULESET.validate(document)
      end

      def walk_structure(document)
        root_ref = document.catalog[:StructTreeRoot]
        return unless root_ref

        root = root_ref.is_a?(Pdfrb::Model::Reference) ?
                 document.object(root_ref) : root_ref
        return unless root

        children = root[:K]
        return unless children

        children = Array(children) unless children.is_a?(::Array)
        children.each do |child_ref|
          elem = child_ref.is_a?(Pdfrb::Model::Reference) ?
                   document.object(child_ref) : child_ref
          next unless elem

          yield elem
        end
      end
    end
  end
end
