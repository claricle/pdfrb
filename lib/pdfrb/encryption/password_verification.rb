# frozen_string_literal: true

require "digest/md5"
require "digest/sha2"

module Pdfrb
  module Encryption
    # Password verification and key derivation for the Standard
    # security handler (s7.6.3.3, Algorithms 2 / 3 / 5 / 6 / 7).
    #
    # All functions are pure (no IO); they consume and return bytes.
    module PasswordVerification
      PADDING_BYTES = [
        0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
        0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
        0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
        0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A
      ].freeze
      private_constant :PADDING_BYTES

      module_function

      # Algorithm 2: derive the encryption key from a user password
      # for revisions 2..4 (RC4 and AES-128).
      def derive_key_rc4(password:, o_entry:, p_flags:, id0:,
                         revision:, key_length_bits:, encrypt_metadata: true)
        padded = pad_password(password)
        digest = Digest::MD5.new
        digest.update(padded)
        digest.update(o_entry.b)
        digest.update([p_flags].pack("V"))
        digest.update(id0.b)
        unless encrypt_metadata
          digest.update("\xFF\xFF\xFF\xFF".b)
        end
        hash = digest.digest
        if revision >= 3
          50.times { hash = Digest::MD5.digest(hash[0, key_length_bits / 8]) }
        end
        hash.byteslice(0, key_length_bits / 8)
      end

      # Algorithm 5: derive the encryption key for revision 6
      # (AES-256, PDF 2.0).
      def derive_key_v6(password:, u_entry:, o_entry:,
                        p_flags:, oe_entry:)
        # PDF 2.0 uses SHA-256 with password + validation salt.
        raise NotImplementedError, "V6 key derivation TBD"
      end

      # Algorithm 4 (R=2): build the /U entry.
      def build_u_r2(file_key)
        rc4 = RC4.new(file_key)
        rc4.process(pack_bytes(PADDING_BYTES))
      end

      # Algorithm 5 (R>=3): build the /U entry.
      def build_u_r3plus(file_key:, id0:, revision:)
        digest = Digest::MD5.new
        digest.update(pack_bytes(PADDING_BYTES))
        digest.update(id0.b)
        hash = digest.digest
        rc4 = RC4.new(file_key)
        encrypted = rc4.process(hash)
        # 19 more rounds with key XORed by round index.
        19.times do |i|
          key = file_key.bytes.map { |b| (b ^ i).chr }.join
          encrypted = RC4.new(key).process(encrypted)
        end
        # Pad / truncate to 32 bytes.
        encrypted = encrypted + ("\x00" * (32 - encrypted.bytesize))
        encrypted.byteslice(0, 32)
      end

      # Algorithm 6: verify a user password. Returns true if it
      # matches.
      def verify_user_password(password:, encrypt_dict:, id0:)
        o_entry = encrypt_dict[:O].b
        p_flags = encrypt_dict[:P]
        revision = encrypt_dict[:R]
        key_bits = (encrypt_dict[:Length] || 40).to_i
        encrypt_metadata = encrypt_dict.fetch(:EncryptMetadata, true)
        key = derive_key_rc4(
          password: password, o_entry: o_entry, p_flags: p_flags,
          id0: id0, revision: revision, key_length_bits: key_bits,
          encrypt_metadata: encrypt_metadata
        )
        expected_u = if revision == 2
                       build_u_r2(key)
                     else
                       build_u_r3plus(file_key: key, id0: id0, revision: revision)
                     end
        u_entry = encrypt_dict[:U].b
        # Compare the first 16 bytes for R>=3.
        slice_len = revision == 2 ? 32 : 16
        expected_u.byteslice(0, slice_len) == u_entry.byteslice(0, slice_len)
      end

      def pad_password(password)
        bytes = password.to_s.b
        padded = bytes + pack_bytes(PADDING_BYTES)
        padded.byteslice(0, 32)
      end
      module_function :pad_password

      def pack_bytes(arr)
        arr.map(&:chr).join.force_encoding(Encoding::BINARY)
      end
      private_class_method :pack_bytes
    end
  end
end
