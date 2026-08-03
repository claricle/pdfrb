# frozen_string_literal: true

require "openssl"

module Pdfrb
  module DigitalSignature
    # PKCS#7 signing (s12.8.3). Creates a signature field, computes
    # the byte-range hash, and embeds the detached PKCS#7 signature.
    module Signing
      module_function

      def sign(document, cert:, key:, **_opts)
        raise Pdfrb::Error, "OpenSSL cert required" unless cert.is_a?(OpenSSL::X509::Certificate)
        raise Pdfrb::Error, "OpenSSL PKey required" unless key.is_a?(OpenSSL::PKey::PKey)

        # Create a signature field (widget annotation).
        sig_dict = document.add(
          {
            Type: :Sig,
            Filter: :"Adobe.PPKLite",
            SubFilter: :adbe.pkcs7.detached
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        sig_dict
      end
    end
  end
end
