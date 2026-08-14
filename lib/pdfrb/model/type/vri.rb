# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # VRI (Validation Related Information) dictionary per ETSI EN
      # 319 142-1 (PAdES) §B.5. Lives in /DSS /VRI map, keyed by the
      # hex-encoded SHA-1 of the signature it validates. Holds the
      # certificates, CRLs, and OCSP responses relevant to one
      # signature.
      class Vri < Pdfrb::Model::Cos::Dictionary
        arlington_object "VRI"

        # /Type — optional, fixed "VRI".
        def type
          value[:Type]&.to_sym
        end

        # /Cert — array of indirect streams, each a DER-encoded
        # X.509 certificate relevant to the signature.
        def certificates(document = nil)
          refs = value[:Cert]
          return [] unless refs

          resolve_refs(refs, document)
        end

        # /CRL — array of indirect streams, each a DER-encoded
        # certificate revocation list.
        def crls(document = nil)
          refs = value[:CRL]
          return [] unless refs

          resolve_refs(refs, document)
        end

        # /OCSP — array of indirect streams, each a DER-encoded
        # OCSP response.
        def ocsp_responses(document = nil)
          refs = value[:OCSP]
          return [] unless refs

          resolve_refs(refs, document)
        end

        # /TU — optional string-text with a human-readable timestamp.
        def timestamp_text
          value[:TU]
        end

        # /TS — optional indirect stream with a timestamp token.
        def timestamp_token(document = nil)
          ref = value[:TS]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end

        private

        def resolve_refs(refs, document)
          return [] unless document

          arr = refs.is_a?(Pdfrb::Model::PdfArray) ? refs.value : refs
          arr = [arr] unless arr.is_a?(::Array)
          arr.filter_map do |r|
            next r unless r.is_a?(Pdfrb::Model::Reference)

            document.object(r)
          end
        end
      end
    end
  end
end
