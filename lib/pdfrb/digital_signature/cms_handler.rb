# frozen_string_literal: true

module Pdfrb
  module DigitalSignature
    module CmsHandler
      module_function

      def type; :"adbe.pkcs7.detached"; end

      def sign(document, cert:, key:, **)
        Pdfrb::DigitalSignature::Signing.sign(document, cert: cert, key: key, **)
      end

      def verify(signature_data, signed_data, trusted_certs: [])
        pkcs7 = OpenSSL::PKCS7.new(signature_data)
        store = OpenSSL::X509::Store.new
        trusted_certs.each { |c| store.add_cert(c) }
        pkcs7.verify(nil, store, signed_data, OpenSSL::PKCS7::DETACHED)
      end
    end
  end
end
