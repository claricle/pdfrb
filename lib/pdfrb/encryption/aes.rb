# frozen_string_literal: true

require "openssl"

module Pdfrb
  module Encryption
    # AES cipher in CBC mode for PDF V4..V6 (s7.6.3.2 / 7.6.3.3).
    # Backed by +openssl+ stdlib for performance and correctness.
    # Caller derives the per-object key and the 16-byte IV (PDF V5+
    # uses IV-in-ciphertext; PDF V4 uses random IV per stream).
    class AES
      attr_reader :key_size, :mode

      def initialize(key_size: 128, mode: :CBC)
        @key_size = key_size
        @mode = mode
      end

      def encrypt(plain, key, iv)
        cipher = openssl_cipher(:encrypt, key.bytesize)
        cipher.key = key.b
        cipher.iv = iv.b
        cipher.padding = 0 # PDF pads itself (PKCS#7)
        out = cipher.update(pad_pkcs7(plain.b, 16)) + cipher.final
        iv.b + out
      end

      def decrypt(ciphertext, key)
        cipher = openssl_cipher(:decrypt, key.bytesize)
        iv = ciphertext.byteslice(0, 16)
        body = ciphertext.byteslice(16..)
        cipher.key = key.b
        cipher.iv = iv
        cipher.padding = 0
        decrypted = cipher.update(body) + cipher.final
        strip_pkcs7(decrypted)
      end

      private

      def openssl_cipher(direction, key_bytes)
        name = case key_bytes
               when 16 then "AES-128-#{@mode}"
               when 32 then "AES-256-#{@mode}"
               else raise Pdfrb::EncryptionError,
                            "unsupported AES key length #{key_bytes}"
               end
        c = OpenSSL::Cipher.new(name)
        direction == :encrypt ? c.encrypt : c.decrypt
        c
      end

      def pad_pkcs7(data, block_size)
        pad = block_size - (data.bytesize % block_size)
        data + (pad.chr * pad)
      end

      def strip_pkcs7(data)
        return data if data.empty?

        pad = data.getbyte(-1)
        return data unless pad && pad.between?(1, 16)

        data.byteslice(0, data.bytesize - pad)
      end
    end
  end
end
