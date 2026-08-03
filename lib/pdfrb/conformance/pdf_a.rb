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
      rs.register(Rule.new(
          id: "a1-3",
          description: "PDF version must not exceed 1.4",
          severity: :error,
          spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            ver = doc.version.to_s
            parts = ver.split(".")
            major = parts[0].to_i
            minor = (parts[1] || "0").to_i
            next nil if major < 1 || (major == 1 && minor <= 4)

            Violation.new(
              rule_id: "a1-3",
              message: "PDF/A-1 requires PDF version <= 1.4, got " + ver,
              object: "header",
              severity: :error,
              spec_clause: "ISO 19005-1 6.1"
            )
          }
        ))
      end

      A1 = RuleSet.new("PDF/A-1").tap do |rs|
        SHARED.rules.each { |rule| rs.register(rule) }
        A1_SPECIFIC.rules.each { |rule| rs.register(rule) }
      end


      A4_SPECIFIC = RuleSet.new("PDF/A-4-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a4-1",
          description: "PDF 2.0 version required",
          severity: :error,
          spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            v = doc.version.to_s
            next nil if v.start_with?("2.0")

            Violation.new(
              rule_id: "a4-1",
              message: "PDF/A-4 requires PDF version 2.0, got #{v}",
              object: "header",
              severity: :error,
              spec_clause: "ISO 19005-4 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "a4-2",
          description: "Filespecs must have /AFRelationship",
          severity: :error,
          spec_clause: "ISO 19005-4 6.2",
          check: ->(doc) {
            violations = []
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :Filespec
              next if obj.value[:AFRelationship]

              violations << Violation.new(
                rule_id: "a4-2",
                message: "Filespec missing /AFRelationship",
                object: obj.value[:F]&.to_s,
                severity: :error,
                spec_clause: "ISO 19005-4 6.2"
              )
            end
            violations.empty? ? nil : violations
          }
        ))

        rs.register(Rule.new(
          id: "a4-3",
          description: "Annotations need appearance streams",
          severity: :error,
          spec_clause: "ISO 19005-4 6.2.3",
          check: ->(doc) {
            violations = []
            doc.each_indirect_object do |annot|
              next unless annot.respond_to?(:value)
              next unless annot.value[:Type] == :Annot

                subtype = annot.value[:Subtype]
                next if subtype == :Link

                rect = annot.value[:Rect]
                next if rect && rect.is_a?(::Array) && rect.length == 4 &&
                        rect[0] == rect[2] && rect[1] == rect[3]

                next if annot.value[:AP]

                violations << Violation.new(
                  rule_id: "a4-3",
                  message: "Annotation /#{subtype} missing /AP appearance stream",
                  object: "Annot",
                  severity: :error,
                  spec_clause: "ISO 19005-4 6.2.3"
                )
            end
            violations.empty? ? nil : violations
          }
        ))

        rs.register(Rule.new(
          id: "a4-4",
          description: "Trailer /ID recommended",
          severity: :warning,
          spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            next nil if doc.trailer && doc.trailer[:ID]

            Violation.new(
              rule_id: "a4-4",
              message: "PDF/A-4 recommends /ID in trailer",
              object: "trailer",
              severity: :warning,
              spec_clause: "ISO 19005-4 6.1"
            )
          }
        ))

        rs.register(Rule.new(
          id: "a4-5",
          description: "XMP /Metadata required",
          severity: :warning,
          spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Metadata]

            Violation.new(
              rule_id: "a4-5",
              message: "PDF/A-4 requires /Catalog/Metadata XMP stream",
              object: "Catalog",
              severity: :warning,
              spec_clause: "ISO 19005-4 6.1"
            )
          }
        ))
      end

      A4 = RuleSet.new("PDF/A-4").tap do |rs|
        SHARED.rules.each { |rule| rs.register(rule) }
        A4_SPECIFIC.rules.each { |rule| rs.register(rule) }
      end


      A2_SPECIFIC = RuleSet.new("PDF/A-2-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a2-1",
          description: "PostScript XObjects prohibited",
          severity: :warning,
          spec_clause: "ISO 19005-2 6.2.4",
          check: ->(doc) {
            violation = nil
            doc.each_indirect_object do |obj|
              next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
              next unless obj[:Subtype] == :PS || obj[:Subtype] == :PSXObject

              violation = Violation.new(
                rule_id: "a2-1",
                message: "PostScript XObjects not allowed in PDF/A-2",
                object: "XObject",
                severity: :warning,
                spec_clause: "ISO 19005-2 6.2.4"
              )
              break
            end
            violation
          }
        ))
      rs.register(Rule.new(
          id: "a2-3",
          description: "PDF version must not be 2.0",
          severity: :error,
          spec_clause: "ISO 19005-2 6.1",
          check: ->(doc) {
            ver = doc.version.to_s
            next nil unless ver.start_with?("2.")

            Violation.new(
              rule_id: "a2-3",
              message: "PDF/A-2 does not allow PDF 2.0, got " + ver,
              object: "header",
              severity: :error,
              spec_clause: "ISO 19005-2 6.1"
            )
          }
        ))

      end

      A3_SPECIFIC = RuleSet.new("PDF/A-3-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a3-1",
          description: "Embedded files must have AFRelationship",
          severity: :error,
          spec_clause: "ISO 19005-3 6.2",
          check: ->(doc) {
            violations = []
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :Filespec

              ef = obj.value[:EF]
              next unless ef
              next if obj.value[:AFRelationship]

              violations << Violation.new(
                rule_id: "a3-1",
                message: "Embedded file missing /AFRelationship on Filespec",
                object: "Filespec",
                severity: :error,
                spec_clause: "ISO 19005-3 6.2"
              )
            end
            violations.empty? ? nil : violations
          }
        ))
      end

      A2 = RuleSet.new("PDF/A-2").tap do |rs|
        SHARED.rules.each { |rule| rs.register(rule) }
        A2_SPECIFIC.rules.each { |rule| rs.register(rule) }
      end

      A3 = RuleSet.new("PDF/A-3").tap do |rs|
        SHARED.rules.each { |rule| rs.register(rule) }
        A3_SPECIFIC.rules.each { |rule| rs.register(rule) }
      end

      LEVEL_RULESETS = {
        a1b: A1, a1a: A1,
        a2b: A2, a2a: A2,
        a3b: A3, a3a: A3,
        a4: A4,
      }.freeze

      def profiles
        { a1b: A1, a1a: A1, a2b: A2, a2a: A2,
          a3b: A3, a3a: A3, a4: A4 }
      end

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
