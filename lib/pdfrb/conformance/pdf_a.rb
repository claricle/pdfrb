# frozen_string_literal: true

module Pdfrb
  module Conformance
    # PDF/A-1/2/3 validation (ISO 19005). Checks a document against
    # the subset constraints. Returns a +Result+ with per-rule verdicts.
    module PdfA
      Result = Struct.new(:level, :passed, :violations, keyword_init: true)
      Violation = Struct.new(:rule, :message, :object, keyword_init: true)

      module_function

      def validate(document, level: :a2b)
        violations = []
        check_no_encryption(document, violations)
        check_has_metadata(document, violations)
        check_embedded_fonts(document, violations)
        Result.new(
          level: level,
          passed: violations.empty?,
          violations: violations
        )
      end

      def check_no_encryption(document, violations)
        return unless document.trailer && document.trailer[:Encrypt]

        violations << Violation.new(
          rule: "no-encryption",
          message: "PDF/A prohibits encryption",
          object: "trailer"
        )
      end
      private_class_method :check_no_encryption

      def check_has_metadata(document, violations)
        return if document.catalog[:Metadata]

        violations << Violation.new(
          rule: "metadata-required",
          message: "PDF/A requires /Catalog/Metadata XMP stream",
          object: "Catalog"
        )
      end
      private_class_method :check_has_metadata

      def check_embedded_fonts(document, violations)
        document.pages.each do |page|
          resources = page.value[:Resources]
          next unless resources

          fonts = resources.is_a?(Pdfrb::Model::Cos::Dictionary) ?
                    resources.value[:Font] : resources[:Font]
          next unless fonts

          fonts.each_value do |ref|
            font = ref.is_a?(Pdfrb::Model::Reference) ?
                     document.object(ref) : ref
            next unless font

            unless font[:FontDescriptor]
              violations << Violation.new(
                rule: "embedded-fonts",
                message: "Font /#{font[:BaseFont]} missing FontDescriptor",
                object: font[:BaseFont]
              )
            end
          end
        end
      end
      private_class_method :check_embedded_fonts
    end
  end
end
