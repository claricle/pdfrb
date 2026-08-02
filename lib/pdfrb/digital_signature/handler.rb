# frozen_string_literal: true

require "openssl"

module Pdfrb
  module DigitalSignature
    # Signature handler: wraps PKCS#7 sign + verify against a cert
    # + private key pair. The high-level API is +sign+ and +verify+.
    module Handler
      module_function

      def sign(document, cert:, key:, **_opts)
        Signing.sign(document, cert: cert, key: key, **_opts)
      end

      def verify(document)
        Verification.verify(document)
      end
    end
  end
end
