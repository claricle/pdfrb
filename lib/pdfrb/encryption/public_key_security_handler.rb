# frozen_string_literal: true

require "openssl"
require "securerandom"

module Pdfrb
  module Encryption
    # Public-key security handler (PDF 1.7 §7.6.5, PKCS#7). Each
    # recipient is encoded as a CMS EnvelopedData; the document
    # encryption key is wrapped with the recipient's public key.
    #
    # Read support: parses /Recipients array elements as PKCS#7
    # EnvelopedData, attempts decryption with a provided private key
    # and certificate. Write support: builds EnvelopedData for a list
    # of recipient certificates via OpenSSL::PKCS7.encrypt, returning
    # DER bytes suitable for the /Recipients array.
    class PublicKeySecurityHandler
      DEFAULT_KEY_LENGTH = 32 # AES-256

      attr_reader :encrypt_dict, :recipients, :private_key, :certificate,
                  :file_key

      # @param encrypt_dict [Hash, nil] the /Encrypt dict (read-side).
      # @param recipients [Array<String>] /Recipients DER bytes.
      # @param private_key [OpenSSL::PKey::RSA, nil] recipient's key.
      # @param certificate [OpenSSL::X509::Certificate, nil] matching cert.
      # @param file_key [String, nil] pre-derived file encryption key
      #   (write-side bypasses unwrap).
      def initialize(encrypt_dict: nil, recipients: [], private_key: nil,
                     certificate: nil, file_key: nil)
        @encrypt_dict = encrypt_dict
        @recipients = recipients
        @private_key = private_key
        @certificate = certificate
        @file_key = file_key
      end

      # Whether this handler can attempt decryption: needs a private
      # key AND a matching certificate AND at least one recipient
      # envelope.
      def can_decrypt?
        !private_key.nil? && !certificate.nil? && recipients.any?
      end

      # Attempt to unwrap the document encryption key using the
      # private key. Returns the raw key bytes, or nil if the key
      # couldn't be extracted.
      def unwrap_key
        return @file_key if @file_key
        return nil unless can_decrypt?

        recipients.each do |envelope_bytes|
          key = try_unwrap_envelope(envelope_bytes)
          return key if key
        end
        nil
      end

      # Build /Recipients array of DER EnvelopedData bytes for each
      # recipient cert. The file_key is wrapped into each envelope.
      # Returns the Array of DER strings.
      def self.build_recipients(file_key:, recipient_certs:, cipher: "AES-256-CBC")
        recipient_certs.map do |cert|
          pkcs7 = OpenSSL::PKCS7.encrypt(
            Array(cert), file_key,
            OpenSSL::Cipher.new(cipher),
            OpenSSL::PKCS7::BINARY
          )
          pkcs7.to_der
        end
      end

      # Construct a write-side handler. Generates a random
      # DEFAULT_KEY_LENGTH-byte file_key, wraps it for each
      # recipient cert, returns a handler whose encrypt_data is
      # ready to use.
      def self.for_writer(recipient_certs:, cipher: "AES-256-CBC",
                          key_length: DEFAULT_KEY_LENGTH)
        file_key = SecureRandom.random_bytes(key_length)
        recipients = build_recipients(file_key: file_key,
                                      recipient_certs: recipient_certs,
                                      cipher: cipher)
        new(recipients: recipients, file_key: file_key)
      end

      # Per-object encryption: AES-256-CBC with IV prefix. The
      # per-object key is SHA-256(file_key ‖ oid ‖ gen).
      def encrypt_string(data, oid, gen)
        encrypt_data(data, oid, gen)
      end

      def encrypt_stream(data, oid, gen)
        encrypt_data(data, oid, gen)
      end

      def decrypt_string(data, oid, gen)
        decrypt_data(data, oid, gen)
      end

      def decrypt_stream(data, oid, gen)
        decrypt_data(data, oid, gen)
      end

      def encrypt_data(data, oid, gen)
        return data unless @file_key

        obj_key = per_object_key(oid, gen)
        iv = SecureRandom.random_bytes(16)
        cipher = OpenSSL::Cipher.new("AES-256-CBC")
        cipher.encrypt
        cipher.key = obj_key
        cipher.iv = iv
        encrypted = cipher.update(data) + cipher.final
        iv + encrypted
      end

      def decrypt_data(data, oid, gen)
        key = unwrap_key
        return data unless key
        return data if data.bytesize < 16

        obj_key = per_object_key(oid, gen, key)
        iv = data.byteslice(0, 16)
        ciphertext = data.byteslice(16..)
        decipher = OpenSSL::Cipher.new("AES-256-CBC")
        decipher.decrypt
        decipher.key = obj_key
        decipher.iv = iv
        decipher.update(ciphertext) + decipher.final
      rescue OpenSSL::Cipher::CipherError
        data
      end

      # Serializer-compatible alias.
      alias encrypt encrypt_data

      private

      # V5-style per-object key derivation. The PDF public-key
      # handler shares the same SHA-256(file_key ‖ oid ‖ gen) trick
      # as the Standard handler V5.
      def per_object_key(oid, gen, key = @file_key)
        Digest::SHA256.digest(key + [oid].pack("V") + [gen].pack("V"))
      end

      def try_unwrap_envelope(envelope_bytes)
        envelope_bytes = envelope_bytes.read if envelope_bytes.is_a?(::IO) ||
          envelope_bytes.is_a?(::StringIO)
        return nil unless envelope_bytes.is_a?(::String)

        pkcs7 = OpenSSL::PKCS7.new(envelope_bytes)
        +""
        pkcs7.decrypt(@private_key, @certificate)
        # OpenSSL::PKCS7#decrypt returns the unwrapped plaintext,
        # which IS the file_key bytes.
        pkcs7.decrypt(@private_key, @certificate)
      rescue StandardError
        nil
      end
    end
  end
end
