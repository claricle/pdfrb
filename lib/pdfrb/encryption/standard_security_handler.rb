# frozen_string_literal: true

require "digest/md5"

module Pdfrb
  module Encryption
    # Standard security handler (s7.6.3). V1..V6 / R2..R6.
    # Owns per-document key derivation + per-object (de)cryption.
    #
    # Supports:
    #   V1, V2 + R2     : RC4 40-bit and 128-bit (PDF 1.4-1.5).
    #   V4   + R4       : RC4 or AES-128 with crypt filters (PDF 1.5+).
    #   V5   + R5       : AES-256 (PDF 1.7 Ext. 3).
    #   V6   + R6       : AES-256 (PDF 2.0).
    #
    # AES uses the openssl stdlib. RC4 is pure Ruby (TODO 119).
    class StandardSecurityHandler < SecurityHandler
      register "Standard", self

      attr_reader :file_key, :version, :revision

      def set_up_decryption(password: "")
        @encrypt_dict = read_encrypt_dict
        return unless @encrypt_dict

        @version = @encrypt_dict[:V].to_i
        @revision = @encrypt_dict[:R].to_i
        id0 = document.trailer[:ID].to_a.first.b
        unless verify_password(password)
          raise Pdfrb::EncryptionError, "incorrect password"
        end
        derive_file_key(password, id0)
      end

      # Verify the user (or owner) password. Returns true on match.
      def verify_password(password)
        PasswordVerification.verify_user_password(
          password: password,
          encrypt_dict: @encrypt_dict,
          id0: document.trailer[:ID].to_a.first.b
        )
      end

      def decrypt(bytes, oid, gen)
        return bytes if @file_key.nil?

        case cipher_type
        when :rc4 then RC4.new(object_key(oid, gen, 16)).process(bytes)
        when :aes then AES.new(key_size: aes_key_bits, mode: :CBC).decrypt(bytes, object_key(oid, gen, aes_key_bits / 8 + 5).byteslice(0, aes_key_bits / 8))
        else bytes
        end
      end

      def encrypt(bytes, oid, gen)
        return bytes if @file_key.nil?

        case cipher_type
        when :rc4 then RC4.new(object_key(oid, gen, 16)).process(bytes)
        when :aes then AES.new(key_size: aes_key_bits, mode: :CBC).encrypt(bytes, object_key(oid, gen, aes_key_bits / 8 + 5).byteslice(0, aes_key_bits / 8), random_iv)
        else bytes
        end
      end

      private

      def read_encrypt_dict
        ref = document.trailer[:Encrypt]
        return nil unless ref

        encrypt = ref.is_a?(Pdfrb::Model::Reference) ?
                    document.object(ref) : ref
        encrypt.is_a?(Pdfrb::Model::Cos::Dictionary) ? encrypt : nil
      end

      def derive_file_key(password, id0)
        @file_key = PasswordVerification.derive_key_rc4(
          password: password,
          o_entry: @encrypt_dict[:O].to_s.b,
          p_flags: @encrypt_dict[:P].to_i,
          id0: id0,
          revision: @revision,
          key_length_bits: (@encrypt_dict[:Length] || 40).to_i,
          encrypt_metadata: @encrypt_dict.fetch(:EncryptMetadata, true)
        )
      end

      def cipher_type
        return :rc4 if @version <= 2
        return :aes if @version >= 4 && @version <= 5

        # V6 (PDF 2.0) — AES-256 always.
        :aes
      end

      def aes_key_bits
        @version >= 5 ? 256 : 128
      end

      # Per-object key per Algorithm 1: MD5(file_key + oid(LE) + gen(LE) + (sAlT for AES)).
      def object_key(oid, gen, output_len)
        md5 = Digest::MD5.new
        md5.update(@file_key)
        md5.update([oid].pack("V"))
        md5.update([gen].pack("V"))
        md5.update("sAlT".b) if cipher_type == :aes
        md5.digest.byteslice(0, output_len)
      end

      def random_iv
        OpenSSL::Random.random_bytes(16)
      rescue StandardError
        require "securerandom"
        SecureRandom.random_bytes(16)
      end
    end
  end
end
