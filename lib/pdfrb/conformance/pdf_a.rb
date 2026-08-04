# frozen_string_literal: true

module Pdfrb
  module Conformance
    module PdfA
      module_function

      SHARED = RuleSet.new("PDF/A-shared").tap do |rs|
        rs.register(Rule.new(
          id: "6.1-1", description: "Encryption prohibited",
          severity: :error, spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil unless doc.trailer && doc.trailer[:Encrypt]
            Violation.new(rule_id: "6.1-1", message: "PDF/A prohibits encryption",
                          object: "trailer", severity: :error, spec_clause: "ISO 19005-1 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "6.1-2", description: "XMP Metadata required",
          severity: :error, spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Metadata]
            Violation.new(rule_id: "6.1-2", message: "PDF/A requires /Catalog/Metadata XMP stream",
                          object: "Catalog", severity: :error, spec_clause: "ISO 19005-1 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "6.1-4", description: "JavaScript prohibited",
          severity: :error, spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              return Violation.new(rule_id: "6.1-4", message: "PDF/A prohibits JavaScript actions",
                                   object: "JavaScript action", severity: :error,
                                   spec_clause: "ISO 19005-1 6.1") if obj.value[:S] == :JavaScript
            end
            nil
          }
        ))
        rs.register(Rule.new(
          id: "6.1-7", description: "Language recommended",
          severity: :warning, spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Lang]
            Violation.new(rule_id: "6.1-7", message: "PDF/A recommends /Catalog/Lang",
                          object: "Catalog", severity: :warning, spec_clause: "ISO 19005-1 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "embedded-fonts", description: "All fonts must be embedded",
          severity: :error, spec_clause: "ISO 19005-1 6.2",
          check: ->(doc) {
            vs = []
            doc.pages.each do |page|
              res = page.value[:Resources]
              next unless res
              fonts = res.is_a?(Pdfrb::Model::Cos::Dictionary) ? res.value[:Font] : res[:Font]
              next unless fonts
              fonts.each_value do |ref|
                f = ref.is_a?(Pdfrb::Model::Reference) ? doc.object(ref) : ref
                next unless f
                next if f[:FontDescriptor]
                vs << Violation.new(rule_id: "embedded-fonts",
                                    message: "Font /#{f[:BaseFont]} missing FontDescriptor",
                                    object: f[:BaseFont]&.to_s, severity: :error,
                                    spec_clause: "ISO 19005-1 6.2")
              end
            end
            vs.empty? ? nil : vs
          }
        ))
      end

      A1_SPECIFIC = RuleSet.new("PDF/A-1-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a1-1", description: "JPEG2000 not allowed in A-1",
          severity: :error, spec_clause: "ISO 19005-1 6.2.4",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
              next unless obj[:Filter] == :JPXDecode
              return Violation.new(rule_id: "a1-1",
                                   message: "JPEG2000 not allowed in PDF/A-1",
                                   object: "XObject", severity: :error,
                                   spec_clause: "ISO 19005-1 6.2.4")
            end
            nil
          }
        ))
        rs.register(Rule.new(
          id: "a1-2", description: "Object streams not allowed in A-1",
          severity: :error, spec_clause: "ISO 19005-1 6.2.4",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :ObjStm
              return Violation.new(rule_id: "a1-2",
                                   message: "Object streams not allowed in PDF/A-1",
                                   object: "ObjStm", severity: :error,
                                   spec_clause: "ISO 19005-1 6.2.4")
            end
            nil
          }
        ))
        rs.register(Rule.new(
          id: "a1-3", description: "PDF version must not exceed 1.4",
          severity: :error, spec_clause: "ISO 19005-1 6.1",
          check: ->(doc) {
            parts = doc.version.to_s.split(".")
            major = parts[0].to_i
            minor = (parts[1] || "0").to_i
            next nil if major < 1 || (major == 1 && minor <= 4)
            Violation.new(rule_id: "a1-3",
                          message: "PDF/A-1 requires version <= 1.4, got " + doc.version.to_s,
                          object: "header", severity: :error, spec_clause: "ISO 19005-1 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "a1-4", description: "LZWDecode not allowed in A-1",
          severity: :error, spec_clause: "ISO 19005-1 6.2.4",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
              f = obj[:Filter]
              fs = f.is_a?(::Array) ? f : [f]
              next unless fs.include?(:LZWDecode)
              return Violation.new(rule_id: "a1-4",
                                   message: "LZWDecode not allowed in PDF/A-1",
                                   object: "Stream", severity: :error,
                                   spec_clause: "ISO 19005-1 6.2.4")
            end
            nil
          }
        ))
      end

      A2_SPECIFIC = RuleSet.new("PDF/A-2-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a2-1", description: "PostScript XObjects prohibited",
          severity: :warning, spec_clause: "ISO 19005-2 6.2.4",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
              next unless obj[:Subtype] == :PS || obj[:Subtype] == :PSXObject
              return Violation.new(rule_id: "a2-1",
                                   message: "PostScript XObjects not allowed in PDF/A-2",
                                   object: "XObject", severity: :warning,
                                   spec_clause: "ISO 19005-2 6.2.4")
            end
            nil
          }
        ))
        rs.register(Rule.new(
          id: "a2-2", description: "Embedded files not allowed in A-2",
          severity: :error, spec_clause: "ISO 19005-2 6.2",
          check: ->(doc) {
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :EmbeddedFile
              return Violation.new(rule_id: "a2-2",
                                   message: "Embedded files not allowed in PDF/A-2 (use PDF/A-3)",
                                   object: "EmbeddedFile", severity: :error,
                                   spec_clause: "ISO 19005-2 6.2")
            end
            nil
          }
        ))
        rs.register(Rule.new(
          id: "a2-3", description: "PDF 2.0 not allowed",
          severity: :error, spec_clause: "ISO 19005-2 6.1",
          check: ->(doc) {
            next nil unless doc.version.to_s.start_with?("2.")
            Violation.new(rule_id: "a2-3",
                          message: "PDF/A-2 does not allow PDF 2.0, got " + doc.version.to_s,
                          object: "header", severity: :error, spec_clause: "ISO 19005-2 6.1")
          }
        ))
      end

      A3_SPECIFIC = RuleSet.new("PDF/A-3-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a3-1", description: "Filespecs must have AFRelationship",
          severity: :error, spec_clause: "ISO 19005-3 6.2",
          check: ->(doc) {
            vs = []
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :Filespec
              next if obj.value[:AFRelationship]
              vs << Violation.new(rule_id: "a3-1",
                                  message: "Filespec missing /AFRelationship",
                                  object: "Filespec", severity: :error,
                                  spec_clause: "ISO 19005-3 6.2")
            end
            vs.empty? ? nil : vs
          }
        ))
      end

      A4_SPECIFIC = RuleSet.new("PDF/A-4-specific").tap do |rs|
        rs.register(Rule.new(
          id: "a4-1", description: "PDF 2.0 required",
          severity: :error, spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            next nil if doc.version.to_s.start_with?("2.0")
            Violation.new(rule_id: "a4-1",
                          message: "PDF/A-4 requires PDF 2.0, got " + doc.version.to_s,
                          object: "header", severity: :error, spec_clause: "ISO 19005-4 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "a4-2", description: "Filespecs must have AFRelationship",
          severity: :error, spec_clause: "ISO 19005-4 6.2",
          check: ->(doc) {
            vs = []
            doc.each_indirect_object do |obj|
              next unless obj.respond_to?(:value)
              next unless obj.value[:Type] == :Filespec
              next if obj.value[:AFRelationship]
              vs << Violation.new(rule_id: "a4-2",
                                  message: "Filespec missing /AFRelationship",
                                  object: "Filespec", severity: :error,
                                  spec_clause: "ISO 19005-4 6.2")
            end
            vs.empty? ? nil : vs
          }
        ))
        rs.register(Rule.new(
          id: "a4-3", description: "Annotations need appearance streams",
          severity: :error, spec_clause: "ISO 19005-4 6.2.3",
          check: ->(doc) {
            vs = []
            doc.each_indirect_object do |annot|
              next unless annot.respond_to?(:value)
              next unless annot.value[:Type] == :Annot
              st = annot.value[:Subtype]
              next if st == :Link
              r = annot.value[:Rect]
              next if r && r.is_a?(::Array) && r.length == 4 && r[0] == r[2] && r[1] == r[3]
              next if annot.value[:AP]
              vs << Violation.new(rule_id: "a4-3",
                                  message: "Annotation /#{st} missing /AP",
                                  object: "Annot", severity: :error,
                                  spec_clause: "ISO 19005-4 6.2.3")
            end
            vs.empty? ? nil : vs
          }
        ))
        rs.register(Rule.new(
          id: "a4-4", description: "Trailer /ID recommended",
          severity: :warning, spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            next nil if doc.trailer && doc.trailer[:ID]
            Violation.new(rule_id: "a4-4", message: "PDF/A-4 recommends /ID in trailer",
                          object: "trailer", severity: :warning, spec_clause: "ISO 19005-4 6.1")
          }
        ))
        rs.register(Rule.new(
          id: "a4-5", description: "Metadata XMP recommended",
          severity: :warning, spec_clause: "ISO 19005-4 6.1",
          check: ->(doc) {
            next nil if doc.catalog[:Metadata]
            Violation.new(rule_id: "a4-5",
                          message: "PDF/A-4 recommends /Catalog/Metadata XMP stream",
                          object: "Catalog", severity: :warning, spec_clause: "ISO 19005-4 6.1")
          }
        ))
      end

      A1 = RuleSet.new("PDF/A-1").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        A1_SPECIFIC.rules.each { |r| rs.register(r) }
      end

      A2 = RuleSet.new("PDF/A-2").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        A2_SPECIFIC.rules.each { |r| rs.register(r) }
      end

      A3 = RuleSet.new("PDF/A-3").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        A3_SPECIFIC.rules.each { |r| rs.register(r) }
      end

      A4 = RuleSet.new("PDF/A-4").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        A4_SPECIFIC.rules.each { |r| rs.register(r) }
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
        rs = LEVEL_RULESETS[level] || SHARED
        rs.validate(document)
      end
    end
  end
end
