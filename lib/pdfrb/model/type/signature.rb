# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Signature dictionary (s12.8.2). Carries the PKCS#7 / CMS
      # signature payload. Lives in a Signature field's /V entry.
      class Signature < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def filter; self[:Filter]; end
        def sub_filter; self[:SubFilter]; end
        def contents; self[:Contents]; end
        def cert; self[:Cert]; end
        def byte_range; self[:ByteRange]; end
        def reference; self[:Reference]; end
        def changes; self[:Changes]; end
        def name; self[:Name]; end
        def reason; self[:Reason]; end
        def location; self[:Location]; end
        def contact_info; self[:ContactInfo]; end
        def m; self[:M]; end
        def prop_build; self[:Prop_Build]; end
        def prop_auth_time; self[:Prop_AuthTime]; end
        def prop_auth_type; self[:Prop_AuthType]; end

        def signed_time
          return nil unless m

          m.is_a?(Time) ? m : parse_pdf_date(m)
        end

        def pkcs7_detached?
          sub_filter == :"adbe.pkcs7.detached"
        end

        def pkcs7_sha1?
          sub_filter == :"adbe.pkcs7.sha1"
        end

        def pkcs1?
          sub_filter == :"adbe.x509.rsa_sha1"
        end

        def has_byte_range?
          byte_range.is_a?(Array) && byte_range.size == 4
        end

        private

        def parse_pdf_date(str)
          return nil unless str

          match = str.to_s.match(/^D:(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?/)
          return nil unless match

          Time.new(match[1].to_i, match[2].to_i, match[3].to_i,
                   (match[4] || 0).to_i, (match[5] || 0).to_i, (match[6] || 0).to_i,
                   "+00:00")
        rescue StandardError
          nil
        end
      end

      # Signature field lock (s12.7.6.5). Specifies which fields are
      # locked after signing.
      class SigFieldLock < Pdfrb::Model::Cos::Dictionary
        def action; self[:Action]&.to_sym; end
        def fields; self[:Fields]; end

        def all_locked?; action == :All; end
        def include_locked?; action == :Include; end
        def exclude_locked?; action == :Exclude; end

        def locked_field_names
          return [] unless include_locked? && fields

          arr = fields.is_a?(Pdfrb::Model::PdfArray) ? fields.to_a : fields
          arr.is_a?(Array) ? arr : []
        end
      end

      # Signature field seed value (s12.7.6.6). Constraints the signer
      # must obey when signing (cert issuers, hash algorithms, etc.).
      class SigFieldSeedValue < Pdfrb::Model::Cos::Dictionary
        def filter; self[:Filter]; end
        def sub_filter; self[:SubFilter]; end
        def digest_method; self[:DigestMethod]; end
        def cert; self[:Cert]; end
        def flags; self[:F] || 0; end
        def legal_attestation; self[:LegalAttestation]; end
        def add_rev_info?; flags & 1 != 0; end
        def add_doc_mdp?; flags & 2 != 0; end
        def add_field_mdp?; flags & 4 != 0; end
        def required_filter?; filter && flags.anybits?(0x100); end
        def required_subfilter?; sub_filter && flags.anybits?(0x200); end
        def required_digest?; digest_method && flags.anybits?(0x400); end
        def required_cert?; cert && flags.anybits?(0x800); end
      end

      # Document Modification Detection and Prevention (DocMDP) —
      # s12.8.2.2. Restricts what edits are allowed after signing.
      class DocMDPTransformParameters < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def p; self[:P]; end
        def v; self[:V]; end

        # P=1: no changes allowed; P=2: minimal changes (form fill);
        # P=3: annotations + form fill.
        def no_changes_allowed?; p == 1; end
        def minimal_changes_allowed?; p == 2; end
        def annotations_allowed?; p == 3; end
      end
    end
  end
end
