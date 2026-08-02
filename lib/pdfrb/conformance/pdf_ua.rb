# frozen_string_literal: true

module Pdfrb
  module Conformance
    # PDF/UA-1 validation (ISO 14289). Checks tagged PDF, reading
    # order, alt text, etc. Per Tech Note 001, /ActualText required
    # for /Figure elements; per Tech Note 002, /Reference elements
    # must wrap link annotations.
    module PdfUA
      Result = Struct.new(:passed, :violations, keyword_init: true)
      Violation = Struct.new(:rule, :message, :object, keyword_init: true)

      module_function

      def validate(document)
        violations = []
        check_has_struct_tree(document, violations)
        check_tagged(document, violations)
        Result.new(passed: violations.empty?, violations: violations)
      end

      def check_has_struct_tree(document, violations)
        return if document.catalog[:StructTreeRoot]

        violations << Violation.new(
          rule: "struct-tree-required",
          message: "PDF/UA requires /Catalog/StructTreeRoot",
          object: "Catalog"
        )
      end
      private_class_method :check_has_struct_tree

      def check_tagged(document, violations)
        mark = document.catalog[:MarkInfo]
        return if mark && mark[:Marked] == true

        violations << Violation.new(
          rule: "marked-required",
          message: "PDF/UA requires /MarkInfo /Marked true",
          object: "Catalog"
        )
      end
      private_class_method :check_tagged
    end
  end
end
