# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # DSS (Document Security Store) per ETSI EN 319 142-1 (PAdES)
      # §B.5. Attached to the Catalog via the /DSS key. Holds the
      # long-term validation material: certificates, CRLs, OCSP
      # responses, and per-signature VRI dictionaries.
      class Dss < Pdfrb::Model::Cos::Dictionary
        arlington_object "DSS"

        # /Type — optional, fixed "DSS".
        def type
          value[:Type]&.to_sym
        end

        # /Certs — array of indirect streams, each a DER-encoded
        # X.509 certificate used by any signature in the document.
        def certificates(document = nil)
          resolve_streams(value[:Certs], document)
        end

        # /OCSPs — array of indirect streams, each a DER-encoded
        # OCSP response.
        def ocsp_responses(document = nil)
          resolve_streams(value[:OCSPs], document)
        end

        # /CRLs — array of indirect streams, each a DER-encoded
        # certificate revocation list.
        def crls(document = nil)
          resolve_streams(value[:CRLs], document)
        end

        # /VRI — optional map of SHA-1 hex digest -> VRI dict for
        # each signature. Returns the raw Hash.
        def vri_map
          value[:VRI]
        end

        # Enumerate each (signature-hash, Vri) pair, resolving the
        # VRI dicts to typed instances.
        def each_vri(document = nil)
          return enum_for(:each_vri, document) unless block_given?

          map = vri_map
          return unless map

          raw = map.is_a?(Pdfrb::Model::Cos::Dictionary) ? map.value : map
          raw.each do |sig_hash, ref|
            resolved = if ref.is_a?(Pdfrb::Model::Reference) && document
                         document.object(ref)
                       else
                         ref
                       end
            next unless resolved && resolved.value.is_a?(::Hash)

            yield sig_hash.to_s, Vri.new(resolved.value)
          end
        end

        # Look up a VRI by the hex-encoded SHA-1 digest of the
        # signature's DER bytes.
        def vri_for(signature_sha1_hex, document = nil)
          each_vri(document).find { |h, _v| h == signature_sha1_hex }&.last
        end

        private

        def resolve_streams(refs, document)
          return [] unless refs && document

          arr = refs.is_a?(Pdfrb::Model::PdfArray) ? refs.value : refs
          arr = [arr] unless arr.is_a?(::Array)
          arr.filter_map { |r| r.is_a?(Pdfrb::Model::Reference) ? document.object(r) : r }
        end
      end
    end
  end
end
