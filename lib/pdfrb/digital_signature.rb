# frozen_string_literal: true

module Pdfrb
  # Digital signatures (s12.8). Stub implementation — full PKCS#7
  # signing + verification needs the OpenSSL PKCS7 module.
  module DigitalSignature
    autoload :Handler, "pdfrb/digital_signature/handler"
    autoload :Signing, "pdfrb/digital_signature/signing"
    autoload :Verification, "pdfrb/digital_signature/verification"
  end
end
