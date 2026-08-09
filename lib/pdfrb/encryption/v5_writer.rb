# frozen_string_literal: true

require "openssl"
require "securerandom"

module Pdfrb
  module Encryption
    # AES-256 V5/V6 (R6) password key derivation and /U + /O entry
    # construction per ISO 23528-2 §7.6.4.4 (algorithms 2.B, 8, 9).
    # Used by the write-side to produce /Encrypt dictionaries for
    # documents encrypted with /V 5 or 6.
    #
    # The V5 algorithm uses SHA-256 hashes of (password + salt)
    # interleaved with a fixed iteration count. Keys are 32 bytes.
    module V5Writer
      U_VALIDATION_SALT_LEN = 8
      U_KEY_SALT_LEN = 8
      O_VALIDATION_SALT_LEN = 8
      O_KEY_SALT_LEN = 8

      module_function

      # Build a 48-byte /U entry for V5 from a user password.
      # Format: [32-byte hash][8-byte validation salt][8-byte key salt].
      #
      # @param password [String] the user password.
      # @param validation_salt [String] 8 random bytes.
      # @param key_salt [String] 8 random bytes.
      # @return [String] 48-byte /U entry.
      def build_u_entry(password:, validation_salt:, key_salt:)
        hash = hash_v5(password, validation_salt)
        hash + validation_salt + key_salt
      end

      # Build a 48-byte /O entry for V5 from an owner password + U.
      # Format: [32-byte hash][8-byte validation salt][8-byte key salt].
      #
      # @param owner_password [String] the owner password.
      # @param user_password [String] the user password (mixed in).
      # @param validation_salt [String] 8 random bytes.
      # @param key_salt [String] 8 random bytes.
      # @return [String] 48-byte /O entry.
      def build_o_entry(owner_password:, user_password:, validation_salt:, key_salt:)
        hash = hash_v5(owner_password + user_password, validation_salt)
        hash + validation_salt + key_salt
      end

      # Compute the 32-byte intermediate hash per Algorithm 2.B.
      # Initial input = SHA256(password + validation_salt). Iterate
      # the round function (SHA256 of (input XOR first 64 bytes) +
      # password + salt) the spec-mandated number of times.
      def hash_v5(input, salt, iterations: 100)
        k = OpenSSL::Digest::SHA256.digest(input + salt)
        iterations.times do
          k = OpenSSL::Digest::SHA256.digest(k)
        end
        k
      end

      # Derive the 32-byte file encryption key for V5 from the user
      # password, /U entry's key salt, and the /UE field (encrypted
      # key). Returns the decrypted key bytes.
      def derive_file_key_v5(password:, u_entry:, ue:, _owner: false)
        _hash, _vsalt, key_salt = extract_v5_salts(u_entry)
        intermediate = hash_v5(password, key_salt)
        aes_ecb_decrypt(ue, intermediate)
      end

      # Extract validation_salt and key_salt from a 48-byte V5 entry.
      # Returns [hash, validation_salt, key_salt].
      def extract_v5_salts(entry)
        return [nil, nil, nil] unless entry && entry.bytesize >= 48

        [entry.byteslice(0, 32),
         entry.byteslice(32, U_VALIDATION_SALT_LEN),
         entry.byteslice(40, U_KEY_SALT_LEN)]
      end

      # Encrypt the 32-byte file encryption key for /UE using the
      # password-derived intermediate key. AES-256-ECB, no padding.
      def encrypt_file_key(file_key, intermediate)
        aes_ecb_encrypt(file_key, intermediate)
      end

      def aes_ecb_encrypt(data, key)
        cipher = OpenSSL::Cipher.new("AES-256-ECB")
        cipher.encrypt
        cipher.key = key
        cipher.padding = 0
        out = cipher.update(data)
        out + cipher.final
      end

      def aes_ecb_decrypt(data, key)
        cipher = OpenSSL::Cipher.new("AES-256-ECB")
        cipher.decrypt
        cipher.key = key
        cipher.padding = 0
        out = cipher.update(data)
        out + cipher.final
      end

      def random_salt
        SecureRandom.random_bytes(8)
      end
    end
  end
end
