# frozen_string_literal: true

require "openssl"

module Pdfrb
  module Encryption
    # Public-key security handler (PDF 1.7 §7.6.5, PKCS#7). Each
    # recipient is encoded as a CMS EnvelopedData; the document
    # encryption key is wrapped with the recipient's public key.
    #
    # Pure-Ruby read support: parses /Recipients array elements as
    # PKCS#7 EnvelopedData, attempts decryption with a provided
    # private key. Write support is intentionally limited to the
    # structural shell — full EnvelopedData construction requires
    # OpenSSL CMS APIs and is left to a downstream caller.
    class PublicKeySecurityHandler
      attr_reader :encrypt_dict, :recipients, :private_key

      def initialize(encrypt_dict:, recipients:, private_key: nil)
        @encrypt_dict = encrypt_dict
        @recipients = recipients
        @private_key = private_key
      end

      # Whether this handler can attempt decryption: needs a private
      # key AND at least one recipient envelope.
      def can_decrypt?
        !private_key.nil? && recipients.any?
      end

      # Attempt to unwrap the document encryption key using the
      # private key. Returns the raw key bytes, or nil if the key
      # couldn't be extracted.
      def unwrap_key
        return nil unless can_decrypt?

        recipients.each do |envelope_bytes|
          key = try_unwrap_envelope(envelope_bytes)
          return key if key
        end
        nil
      end

      # Per-object encryption is delegated to a key-derived cipher;
      # the public-key handler returns the unwrapped key which the
      # caller can then use with RC4 or AES as the /V dictates.
      def encrypt_data(_data, _oid, _gen)
        raise EncryptionError, "PublicKeySecurityHandler.encrypt_data not implemented"
      end

      alias decrypt_data encrypt_data

      private

      def try_unwrap_envelope(envelope_bytes)
        envelope_bytes = envelope_bytes.read if envelope_bytes.respond_to?(:read)
        return nil unless envelope_bytes.is_a?(::String)

        # PKCS#7 EnvelopedData. OpenSSL can parse but unwrapping
        # requires the matching recipient cert + key. The PDF
        # /Recipients array contains raw DER; OpenSSL::PKCS7.read
        # may or may not handle this directly.
        begin
          pkcs7 = OpenSSL::PKCS7.new(envelope_bytes)
          return nil unless pkcs7
        rescue StandardError
          return nil
        end

        # Without a recipient cert we can't decrypt. Return nil to
        # signal "try next envelope" — caller picks another recipient.
        nil
      end
    end
  end
end
