# frozen_string_literal: true

require "openssl"

module Pdfrb
  module DigitalSignature
    # PKCS#7 signature verification (s12.8.3). Extracts signature
    # from the document, checks byte-range integrity, and verifies
    # the cert chain against the system trust store.
    module Verification
      Result = Struct.new(:signer, :valid?, :byte_range_ok?,
                          :cert_chain, :error, keyword_init: true)

      module_function

      def verify(document)
        Result.new(signer: nil, valid?: false, byte_range_ok?: nil,
                   cert_chain: [], error: "verification stub — not yet implemented")
      end
    end
  end
end
