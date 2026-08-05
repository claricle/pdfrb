# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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
    end
  end
end
