# frozen_string_literal: true

# rubocop:disable-next Metrics/BlockLength
module Pdfrb
  module Conformance
    # PDF/VT conformance per ISO 16612-2. PDF/VT is the variable
    # data printing standard for transactional and direct mail
    # workflows. Two conformance levels:
    #
    #   PDF/VT-1: rooted in PDF/X-4 (production-ready print environment)
    #   PDF/VT-2: rooted in PDF/X-4 but allows external references
    #
    # Both levels require:
    #   * /MarkInfo /Marked true (tagged)
    #   * /OutputIntents present
    #   * /DPartRoot dict on the Catalog (Document Part registry)
    #   * All fonts embedded
    #   * No encryption
    module PdfVT
      module_function

      SHARED = RuleSet.new("PDF/VT-shared").tap do |rs|
        rs.register(Rule.new(
                      id: "vt-1",
                      description: "/MarkInfo /Marked true required",
                      severity: :error,
                      spec_clause: "ISO 16612-2 6.2.1",
                      check: ->(doc) {
                        mark = doc.catalog[:MarkInfo]
                        mark = doc.object(mark) if mark.is_a?(Pdfrb::Model::Reference)
                        next nil if mark && mark[:Marked] == true

                        Violation.new(
                          rule_id: "vt-1",
                          message: "PDF/VT requires /MarkInfo /Marked true",
                          object: "Catalog/MarkInfo",
                          severity: :error,
                          spec_clause: "ISO 16612-2 6.2.1"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "vt-2",
                      description: "OutputIntents required",
                      severity: :error,
                      spec_clause: "ISO 16612-2 6.2.2",
                      check: ->(doc) {
                        next nil if doc.catalog[:OutputIntents]

                        Violation.new(
                          rule_id: "vt-2",
                          message: "PDF/VT requires /OutputIntents",
                          object: "Catalog/OutputIntents",
                          severity: :error,
                          spec_clause: "ISO 16612-2 6.2.2"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "vt-3",
                      description: "/DPartRoot required for variable data partitioning",
                      severity: :error,
                      spec_clause: "ISO 16612-2 6.3",
                      check: ->(doc) {
                        next nil if doc.catalog[:DPartRoot]

                        Violation.new(
                          rule_id: "vt-3",
                          message: "PDF/VT requires /DPartRoot on Catalog",
                          object: "Catalog/DPartRoot",
                          severity: :error,
                          spec_clause: "ISO 16612-2 6.3"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "vt-4",
                      description: "Encryption is forbidden",
                      severity: :error,
                      spec_clause: "ISO 16612-2 6.2.4",
                      check: ->(doc) {
                        next nil unless doc.trailer && doc.trailer[:Encrypt]

                        Violation.new(
                          rule_id: "vt-4",
                          message: "PDF/VT prohibits encryption",
                          object: "Trailer/Encrypt",
                          severity: :error,
                          spec_clause: "ISO 16612-2 6.2.4"
                        )
                      }
                    ))
      end

      VT1 = RuleSet.new("PDF/VT-1").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
      end

      VT2 = RuleSet.new("PDF/VT-2").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "vt2-1",
                      description: "PDF/VT-2 permits external OutputIntents references",
                      severity: :warning,
                      spec_clause: "ISO 16612-2 6.4.2",
                      check: ->(_doc) {}
                    ))
      end

      LEVEL_RULESETS = {
        vt1: VT1, vt2: VT2
      }.freeze

      def profiles
        LEVEL_RULESETS.dup
      end

      def validate(document, level: :vt1)
        rs = LEVEL_RULESETS[level] || SHARED
        rs.validate(document)
      end
    end
  end
end
