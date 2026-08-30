# frozen_string_literal: true

module Pdfrb
  # Digital signatures (s12.8). PKCS#7 detached signing + verification
  # against a cert + private key pair. CMS handler is the default
  # +adbe.pkcs7.detached+ subfilter.
  module DigitalSignature
    autoload :Handler, "pdfrb/digital_signature/handler"
    autoload :Signing, "pdfrb/digital_signature/signing"
    autoload :Verification, "pdfrb/digital_signature/verification"
    autoload :VerificationResult, "pdfrb/digital_signature/verification_result"
    autoload :CmsHandler, "pdfrb/digital_signature/cms_handler"
    autoload :TimestampHandler, "pdfrb/digital_signature/timestamp_handler"
    autoload :TimestampClient, "pdfrb/digital_signature/timestamp_client"

    module_function

    # Resolve the handler class for +sub_filter+. Constant references
    # live inside the case so the autoloads above defer loading the
    # handlers (and their OpenSSL surface) until an actual
    # sign/verify call needs them.
    def handler_for(sub_filter)
      case sub_filter.to_sym
      when :"adbe.pkcs7.detached", :"adbe.pkcs7.sha1" then CmsHandler
      when :"adbe.revision" then TimestampHandler
      end
    end

    def sign(document, cert:, key:, **)
      Handler.sign(document, cert: cert, key: key, **)
    end

    def verify(document, trusted_certs: [])
      Handler.verify(document, trusted_certs: trusted_certs)
    end
  end
end
