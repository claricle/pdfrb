# frozen_string_literal: true

module Pdfrb
  module Conformance
    module PdfA
      module_function

      SHARED = RuleSet.new("PDF/A-shared").tap do |rs|
        rs.register(Rule.new(
          id: "6.1-1",
          description: "Encryption is prohibited",
          severity: :error,
          spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil unless doc.trailer && doc.trailer[:Encrypt]

            Violation.new(
              rule_id: "6.1-1",
              message: "PDF/A prohibits encryption",
              object: "trailer",
              severity: :error,
              spec_clause: "ISO 19005-1 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "6.1-2",
          description: "XMP Metadata stream required",
          severity: :error,
          spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Metadata]

            Violation.new(
              rule_id: "6.1-2",
              message: "PDF/A requires /Catalog/Metadata XMP stream",
              object: "Catalog",
              severity: :error,
              spec_clause: "ISO 19005-1 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "6.1-4",
          description: "JavaScript actions prohibited",
          severity: :error,
          spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            found = find_javascript(doc)
            next nil unless found

            Violation.new(
              rule_id: "6.1-4",
              message: "PDF/A prohibits JavaScript actions",
              object: found,
              severity: :error,
              spec_clause: "ISO 19005-1 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "6.1-7",
          description: "Document language should be set",
          severity: :warning,
          spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Lang]

            Violation.new(
              rule_id: "6.1-7",
              message: "PDF/A recommends setting /Catalog/Lang",
              object: "Catalog",
              severity: :warning,
              spec_clause: "ISO 19005-1 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "embedded-fonts",
          description: "All fonts must be embedded",
          severity: :error,
          spec_clause: "ISO 19005-1 6.2",
          check: ->(doc) {
            violations = []
            doc.pages.each do |page|
              resources = page.value[:Resources]
              next unless resources

              fonts = resources.is_a?(Pdfrb::Model::Cos::Dictionary) ?
                        resources.value[:Font] : resources[:Font]
              next unless fonts

              fonts.each_value do |ref|
                font = ref.is_a?(Pdfrb::Model::Reference) ?
                         doc.object(ref) : ref
                next unless font
                next if font[:FontDescriptor]

                violations << Violation.new(
                  rule_id: "embedded-fonts",
                  message: "Font /#{font[:BaseFont]} missing FontDescriptor",
                  object: font[:BaseFont]&.to_s,
                  severity: :error,
                  spec_clause: "ISO 19005-1 6.2"
                )
              end
            end
            violations.empty? ? nil : violations
          }
        ))
      end

      A1_SPECIFIC = RuleSet.new("PDF/A-1-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a1-1",
          description: "JPEG2000 not allowed in PDF/A-1",
          severity: :error,
          spec_clause: "ISO 19005-1 6.2.4",
          check: ->(doc) {
            violation = nil
            doc.each_indirect_object do |obj|
              next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
              next unless obj[:Filter] == :JPXDecode

              violation = Violation.new(
                rule_id: "a1-1",
                message: "JPEG2000 (JPXDecode) not allowed in PDF/A-1",
                object: "XObject",
                severity: :error,
                spec_clause: "ISO 19005-1 6.2.4"
              )
              break
            end
            violation
          }
        ))
      end

      A1 = RuleSet.new("PDF/A-1").tap do |rs|
        SHARED.rules.each { |rule| rs.register(rule) }
        A1_SPECIFIC.rules.each { |rule| rs.register(rule) }
      end

      LEVEL_RULESETS = {
        a1b: A1, a1a: A1,
        a2b: SHARED, a2a: SHARED,
        a3b: SHARED, a3a: SHARED,
      }.freeze

      def validate(document, level: :a2b)
        ruleset = LEVEL_RULESETS[level] || SHARED
        ruleset.validate(document)
      end

      def find_javascript(document)
        document.each_indirect_object do |obj|
          next unless obj.respond_to?(:value)
          return "JavaScript action" if obj.value[:S] == :JavaScript
        end
        nil
      end
      private_class_method :find_javascript
    end
  end
end
