# frozen_string_literal: true

# rubocop:disable-next Metrics/BlockLength
module Pdfrb
  module Conformance
    # PAdES (ETSI EN 319 142-1) signature profile validation. Four
    # baseline levels build on each other:
    #
    #   B-B: Basic signatures — just the document hash + signer cert.
    #   B-T: B-B + trusted timestamp (RFC 3161) on the signature.
    #   B-LT: B-T + long-term validation material (DSS dictionary
    #         with revocation data, signer certs, TSA cert chain).
    #   B-LTA: B-LT + archival timestamp protecting the DSS itself.
    #
    # Each rule set checks signature dictionaries on the document's
    # /AcroForm /Fields for the required components per level.
    module Pades
      ALLOWED_SIGNATURE_TYPES = %i[Sig DocTimeStamp].freeze

      module_function

      SHARED = RuleSet.new("PAdES-shared").tap do |rs|
        rs.register(Rule.new(
                      id: "pades-1",
                      description: "At least one signature field must be present",
                      severity: :error,
                      spec_clause: "ETSI EN 319 142-1 5.2",
                      check: ->(doc) {
                        next nil if signature_fields(doc).any?

                        Violation.new(
                          rule_id: "pades-1",
                          message: "PAdES requires at least one signature field",
                          object: "AcroForm/Fields",
                          severity: :error,
                          spec_clause: "ETSI EN 319 142-1 5.2"
                        )
                      }
                    ))
      end

      BB = RuleSet.new("PAdES-B-B").tap do |rs|
        SHARED.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "bb-1",
                      description: "B-B: each signature must have /Type /Sig or /DocTimeStamp",
                      severity: :error,
                      spec_clause: "ETSI EN 319 142-1 5.3",
                      check: ->(doc) {
                        vs = []
                        signature_fields(doc).each do |field|
                          v = field[:V]
                          next unless v

                          v_obj = v.is_a?(Pdfrb::Model::Reference) ? doc.object(v) : v
                          next if v_obj && ALLOWED_SIGNATURE_TYPES.include?(v_obj[:Type]&.to_sym)

                          vs << Violation.new(
                            rule_id: "bb-1",
                            message: "Signature V must be /Type /Sig or /DocTimeStamp",
                            object: "Field/V",
                            severity: :error,
                            spec_clause: "ETSI EN 319 142-1 5.3"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))
      end

      BT = RuleSet.new("PAdES-B-T").tap do |rs|
        BB.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "bt-1",
                      description: "B-T: signature must include a trusted timestamp",
                      severity: :error,
                      spec_clause: "ETSI EN 319 142-1 5.4",
                      check: ->(doc) {
                        vs = []
                        signature_fields(doc).each do |field|
                          v = field[:V]
                          next unless v

                          v_obj = v.is_a?(Pdfrb::Model::Reference) ? doc.object(v) : v
                          has_timestamp = v_obj && (
                            v_obj[:Type]&.to_sym == :DocTimeStamp ||
                              (v_obj[:ByteRange] && timestamp_in_signature?(v_obj))
                          )
                          next if has_timestamp

                          vs << Violation.new(
                            rule_id: "bt-1",
                            message: "B-T requires a trusted timestamp (RFC 3161)",
                            object: "Field/V",
                            severity: :error,
                            spec_clause: "ETSI EN 319 142-1 5.4"
                          )
                        end
                        vs.empty? ? nil : vs
                      }
                    ))
      end

      BLT = RuleSet.new("PAdES-B-LT").tap do |rs|
        BT.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "blt-1",
                      description: "B-LT: DSS dictionary required for LTV material",
                      severity: :error,
                      spec_clause: "ETSI EN 319 142-1 5.5",
                      check: ->(doc) {
                        next nil if doc.catalog[:DSS]

                        Violation.new(
                          rule_id: "blt-1",
                          message: "B-LT requires /DSS dictionary with validation material",
                          object: "Catalog/DSS",
                          severity: :error,
                          spec_clause: "ETSI EN 319 142-1 5.5"
                        )
                      }
                    ))
      end

      BLTA = RuleSet.new("PAdES-B-LTA").tap do |rs|
        BLT.rules.each { |r| rs.register(r) }
        rs.register(Rule.new(
                      id: "blta-1",
                      description: "B-LTA: archival Document Time Stamp required",
                      severity: :error,
                      spec_clause: "ETSI EN 319 142-1 5.6",
                      check: ->(doc) {
                        # B-LTA needs a DocTimeStamp as the last signature,
                        # protecting the DSS.
                        has_archival = signature_fields(doc).any? do |field|
                          v = field[:V]
                          v_obj = v.is_a?(Pdfrb::Model::Reference) ? doc.object(v) : v
                          v_obj && v_obj[:Type]&.to_sym == :DocTimeStamp
                        end
                        next nil if has_archival

                        Violation.new(
                          rule_id: "blta-1",
                          message: "B-LTA requires an archival Document Time Stamp",
                          object: "AcroForm/Fields",
                          severity: :error,
                          spec_clause: "ETSI EN 319 142-1 5.6"
                        )
                      }
                    ))
      end

      LEVEL_RULESETS = {
        "B-B": BB, "B-T": BT, "B-LT": BLT, "B-LTA": BLTA
      }.freeze

      def profiles
        LEVEL_RULESETS.dup
      end

      def validate(document, level: :"B-B")
        rs = LEVEL_RULESETS[level] || SHARED
        rs.validate(document)
      end

      def signature_fields(document)
        acroform = document.catalog[:AcroForm]
        acroform = document.object(acroform) if acroform.is_a?(Pdfrb::Model::Reference)
        return [] unless acroform

        fields = acroform[:Fields]
        fields = fields.value if fields.is_a?(Pdfrb::Model::PdfArray)
        return [] unless fields.is_a?(::Array)

        fields.filter_map do |ref|
          obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
          next nil unless obj

          obj[:FT]&.to_sym == :Sig ? obj : nil
        end
      end

      # Heuristic: look for the standard ASN.1 timestamp OID
      # (1.2.840.113549.1.7.2 signedData, with a TSTInfo content
      # type). Real validation requires parsing the PKCS#7 — out of
      # scope for this rule set, which only checks the structural
      # presence of a ByteRange + Contents long enough to hold a
      # timestamp token.
      def timestamp_in_signature?(signature)
        contents = signature[:Contents]
        return false unless contents.is_a?(::String)

        contents.bytesize > 1024
      end
    end
  end
end
