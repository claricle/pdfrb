# frozen_string_literal: true

# rubocop:disable-next Metrics/BlockLength
module Pdfrb
  module Conformance
    # Long-Term Validation (LTV) per ETSI EN 319 102-1 Annex B. LTV
    # preserves the validity of a signature beyond the validity
    # period of the signer's certificate by archiving revocation
    # data and timestamping the archive over time.
    #
    # LTV requires:
    #   * At least one signature with /ByteRange and /Contents.
    #   * /DSS dictionary on Catalog with /Certs, /CRLs, /OCSPs as
    #     applicable.
    #   * For archival (LTA): a /DocumentTimeStamp on the catalog.
    module Ltv
      module_function

      RULESET = RuleSet.new("LTV").tap do |rs|
        rs.register(Rule.new(
                      id: "ltv-1",
                      description: "/DSS dictionary required for LTV",
                      severity: :error,
                      spec_clause: "ETSI EN 319 102-1 B.5",
                      check: ->(doc) {
                        next nil if doc.catalog[:DSS]

                        Violation.new(
                          rule_id: "ltv-1",
                          message: "LTV requires /DSS dictionary on Catalog",
                          object: "Catalog/DSS",
                          severity: :error,
                          spec_clause: "ETSI EN 319 102-1 B.5"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "ltv-2",
                      description: "/DSS must contain validation material",
                      severity: :warning,
                      spec_clause: "ETSI EN 319 102-1 B.5",
                      check: ->(doc) {
                        dss = doc.catalog[:DSS]
                        dss = doc.object(dss) if dss.is_a?(Pdfrb::Model::Reference)
                        next nil unless dss

                        has_material = dss[:Certs] || dss[:CRLs] || dss[:OCSPs] ||
                                       dss[:VRI]
                        next nil if has_material

                        Violation.new(
                          rule_id: "ltv-2",
                          message: "/DSS is empty (no /Certs, /CRLs, /OCSPs, or /VRI)",
                          object: "Catalog/DSS",
                          severity: :warning,
                          spec_clause: "ETSI EN 319 102-1 B.5"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "ltv-3",
                      description: "At least one signature should be present",
                      severity: :warning,
                      spec_clause: "ETSI EN 319 102-1 B.4",
                      check: ->(doc) {
                        fields = Pdfrb::Conformance::Pades.signature_fields(doc)
                        next nil if fields.any?

                        Violation.new(
                          rule_id: "ltv-3",
                          message: "LTV document has no signatures to validate",
                          object: "AcroForm/Fields",
                          severity: :warning,
                          spec_clause: "ETSI EN 319 102-1 B.4"
                        )
                      }
                    ))

        rs.register(Rule.new(
                      id: "ltv-4",
                      description: "Document Time Stamp for archival (LTA)",
                      severity: :warning,
                      spec_clause: "ETSI EN 319 102-1 B.6",
                      check: ->(doc) {
                        fields = Pdfrb::Conformance::Pades.signature_fields(doc)
                        has_archival = fields.any? do |field|
                          v = field[:V]
                          v_obj = v.is_a?(Pdfrb::Model::Reference) ? doc.object(v) : v
                          v_obj && v_obj[:Type]&.to_sym == :DocTimeStamp
                        end
                        next nil if has_archival

                        Violation.new(
                          rule_id: "ltv-4",
                          message: "Long-Term Archival (LTA) recommends a Document Time Stamp",
                          object: "AcroForm/Fields",
                          severity: :warning,
                          spec_clause: "ETSI EN 319 102-1 B.6"
                        )
                      }
                    ))
      end

      def validate(document)
        RULESET.validate(document)
      end
    end
  end
end
