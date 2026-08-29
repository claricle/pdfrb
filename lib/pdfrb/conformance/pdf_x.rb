# frozen_string_literal: true

module Pdfrb
  module Conformance
    # PDF/X conformance profiles (ISO 15930). PDF/X is the graphic arts
    # exchange standard for print production. Key constraints:
    #
    #   PDF/X-1a (ISO 15930-1): CMYK + spot only, no RGB, no live ICC
    #   PDF/X-3  (ISO 15930-3): allows calibrated RGB and Lab
    #   PDF/X-4  (ISO 15930-7): allows transparency and layers
    #   PDF/X-6  (ISO 15930-11): PDF 2.0 based
    #
    # Shared requirements across all X profiles:
    #   * Output intent required (/OutputIntents with /GTS_PDFX)
    #   * BleedBox and TrimBox required
    #   * All fonts embedded
    #   * No encryption
    #   * No actions (/AA), no JavaScript
    #   * /Trapped key present (True/False/Unknown)
    module PdfX
      module_function

      def profiles
        { x1a: X1A, x3: X3, x4: X4, x6: X6 }
      end

      def validate(document, level: :x4)
        rule_set_for(level).validate(document)
      end

      def rule_set_for(level)
        case level.to_s
        when /\Ax1/i then X1A
        when /\Ax3/i then X3
        when /\Ax6/i then X6
        else X4
        end
      end

      SHARED = RuleSet.new("PDF/X-shared").tap do |rs| # rubocop:disable Metrics/BlockLength
        rs.register(Rule.new(
                      id: "px-1",
                      description: "Output intent required",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.1",
                      check: ->(doc) {
                        next nil if has_pdfx_output_intent?(doc)

                        Violation.new(rule_id: "px-1",
                                      message: "PDF/X requires a /GTS_PDFX output intent",
                                      object: "Catalog", severity: :error,
                                      spec_clause: "ISO 15930 §6.1")
                      }
                    ))

        rs.register(Rule.new(
                      id: "px-2",
                      description: "TrimBox or ArtBox required on every page",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.2.3",
                      check: ->(doc) {
                        violations = []
                        doc.pages.each do |page|
                          next if page.value[:TrimBox] || page.value[:ArtBox]

                          violations << Violation.new(
                            rule_id: "px-2",
                            message: "Page missing /TrimBox (required for PDF/X)",
                            object: page.oid, severity: :error,
                            spec_clause: "ISO 15930 §6.2.3"
                          )
                        end
                        violations.empty? ? nil : violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "px-3",
                      description: "All fonts must be embedded",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.3",
                      check: ->(doc) {
                        violations = []
                        doc.pages.each do |page|
                          resources = page.value[:Resources]
                          next unless resources

                          fonts = if resources.is_a?(Pdfrb::Model::Cos::Dictionary)
                                    resources.value[:Font]
                                  else
                                    resources[:Font]
                                  end
                          next unless fonts

                          fonts_hash = fonts.is_a?(Pdfrb::Model::Cos::Dictionary) ? fonts.value : fonts
                          fonts_hash&.each_value do |ref|
                            font = doc.resolve(ref)
                            next unless font

                            fd = font[:FontDescriptor]
                            next if fd

                            violations << Violation.new(
                              rule_id: "px-3",
                              message: "Font /#{font[:BaseFont]} not embedded",
                              object: font[:BaseFont], severity: :error,
                              spec_clause: "ISO 15930 §6.3"
                            )
                          end
                        end
                        violations.empty? ? nil : violations
                      }
                    ))

        rs.register(Rule.new(
                      id: "px-4",
                      description: "Encryption prohibited",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.1.3",
                      check: ->(doc) {
                        next nil unless doc.trailer && doc.trailer[:Encrypt]

                        Violation.new(rule_id: "px-4",
                                      message: "PDF/X prohibits encryption",
                                      object: "trailer", severity: :error,
                                      spec_clause: "ISO 15930 §6.1.3")
                      }
                    ))

        rs.register(Rule.new(
                      id: "px-5",
                      description: "/Trapped key required",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.1.6",
                      check: ->(doc) {
                        info = PdfX.info_dict(doc)
                        next nil if info && info[:Trapped]

                        Violation.new(rule_id: "px-5",
                                      message: "Document Info /Trapped key required (True, False, or Unknown)",
                                      object: "Info", severity: :error,
                                      spec_clause: "ISO 15930 §6.1.6")
                      }
                    ))

        rs.register(Rule.new(
                      id: "px-6",
                      description: "No JavaScript or form actions",
                      severity: :error,
                      spec_clause: "ISO 15930 §6.5",
                      check: ->(doc) {
                        violations = []
                        doc.each_indirect_object do |obj|
                          next unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)

                          s = obj[:S]
                          next unless [:JavaScript, :JS, :Launch, :URI].include?(s)

                          violations << Violation.new(
                            rule_id: "px-6",
                            message: "Action /#{s} prohibited in PDF/X",
                            object: obj.oid, severity: :error,
                            spec_clause: "ISO 15930 §6.5"
                          )
                        end
                        violations.empty? ? nil : violations
                      }
                    ))
      end

      def has_pdfx_output_intent?(doc)
        intents = doc.catalog.value[:OutputIntents]
        return false unless intents

        intents = [intents] unless intents.is_a?(::Array)
        intents.any? do |ref|
          obj = doc.resolve(ref)
          obj && obj.value[:S] == :GTS_PDFX
        end
      end

      def info_dict(doc)
        info_ref = doc.trailer && doc.trailer[:Info]
        return nil unless info_ref

        doc.object(info_ref)
      end

      # X-1a: strictest — CMYK + spot only
      X1A = RuleSet.new("PDF/X-1a").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "x1a-1",
                      description: "PDF/X-1a: no RGB or Lab color spaces",
                      severity: :error,
                      spec_clause: "ISO 15930-1 §6.3.8",
                      check: ->(doc) {
                        violations = []
                        scan_color_spaces(doc) do |cs, oid|
                          case cs.to_s
                          when "DeviceRGB", "CalRGB", "CalGray", "Lab"
                            violations << Violation.new(
                              rule_id: "x1a-1",
                              message: "PDF/X-1a prohibits #{cs} color space",
                              object: oid, severity: :error,
                              spec_clause: "ISO 15930-1 §6.3.8"
                            )
                          end
                        end
                        violations.empty? ? nil : violations
                      }
                    ))
      end

      # X-3: allows calibrated RGB and Lab
      X3 = RuleSet.new("PDF/X-3").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
      end

      # X-4: allows transparency and layers
      X4 = RuleSet.new("PDF/X-4").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
      end

      # X-6 specific rules. Defined as lambdas (not module methods)
      # so they are in scope when X6 is built.
      X6_VERSION_RULE = Rule.new(
        id: "x6-1",
        description: "PDF/X-6 requires PDF 2.0",
        severity: :error,
        spec_clause: "ISO 15930-11 6.1",
        check: ->(doc) {
          v = doc.version.to_s
          next nil if compare_versions(v, "2.0") >= 0

          Violation.new(
            rule_id: "x6-1",
            message: "PDF/X-6 requires PDF version 2.0 (was #{v})",
            object: "Header",
            severity: :error,
            spec_clause: "ISO 15930-11 6.1"
          )
        }
      )

      X6_OUTPUT_INTENT_RULE = Rule.new(
        id: "x6-2",
        description: "PDF/X-6 OutputIntents should use /S /GTS_PDFX",
        severity: :warning,
        spec_clause: "ISO 15930-11 6.2.4",
        check: ->(doc) {
          intents = doc.catalog[:OutputIntents]
          intents_array = case intents
                          when ::Array then intents
                          when Pdfrb::Model::PdfArray then intents.value
                          when nil then []
                          else [intents]
                          end
          has_pdfx = intents_array.any? do |i|
            obj = doc.resolve(i)
            obj && obj[:S] == :GTS_PDFX
          end
          next nil if has_pdfx

          Violation.new(
            rule_id: "x6-2",
            message: "PDF/X-6 OutputIntents should include an entry with /S /GTS_PDFX",
            object: "Catalog/OutputIntents",
            severity: :warning,
            spec_clause: "ISO 15930-11 6.2.4"
          )
        }
      )

      # X-6: ISO 15930-11 — PDF 2.0 based. Adds the PDF 2.0 base
      # version requirement and PDF/X-4's relaxed rules.
      X6 = RuleSet.new("PDF/X-6").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        rs.register(X6_VERSION_RULE)
        rs.register(X6_OUTPUT_INTENT_RULE)
      end

      def compare_versions(a, b)
        aa = a.to_s.split(".").map(&:to_i)
        bb = b.to_s.split(".").map(&:to_i)
        (aa <=> bb) || 0
      end

      def scan_color_spaces(doc, &block)
        doc.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)

          cs = obj.value[:ColorSpace]
          next unless cs

          yield_color_space(cs, obj.oid, &block)
        end
      end

      def yield_color_space(cs, oid, &block)
        case cs
        when ::Symbol then yield cs, oid
        when ::Array
          cs.each { |e| yield_color_space(e, oid, &block) }
        when ::Hash
          cs.each_value { |v| yield_color_space(v, oid, &block) }
        end
      end
      private_class_method :yield_color_space
    end
  end
end
