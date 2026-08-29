# frozen_string_literal: true

require "digest/md5"
require "securerandom"

module Pdfrb
  class Document
    # Encryption facade. Exposes a clean API for encrypting a
    # document (builds the /Encrypt dict, wires the security handler
    # into the writer config) and for checking encryption status.
    #
    # Usage:
    #   doc.encryption.encrypt!(
    #     user_password: "reader",
    #     owner_password: "owner",
    #     bits: 128,
    #     permissions: %i[print copy]
    #   )
    #   doc.write("encrypted.pdf")
    class Encryption
      PERMISSION_FLAGS = {
        print: 1 << 2,
        modify: 1 << 3,
        copy: 1 << 4,
        annotate: 1 << 5,
        fill: 1 << 8,
        extract: 1 << 9,
        assemble: 1 << 10,
        print_hq: 1 << 11,
      }.freeze

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Encrypt this document with a user + owner password.
      #
      # @param user_password [String] the password readers need to open.
      # @param owner_password [String] the password that grants full
      #   permissions (defaults to user_password).
      # @param bits [Integer] key length: 40, 128 (AES-128), or
      #   256 (AES-256 R6).
      # @param permissions [Array<Symbol>] granted permissions from
      #   PERMISSION_FLAGS keys; any not listed are denied.
      # @return [Pdfrb::Model::Cos::Dictionary] the /Encrypt dict.
      def encrypt!(user_password:, owner_password: nil, bits: 128,
                   permissions: PERMISSION_FLAGS.keys)
        case bits
        when 256 then encrypt_v5(user_password, owner_password || user_password, permissions)
        when 128 then encrypt_rc4(user_password, owner_password || user_password,
                                  permissions, v: 4, r: 4, length: 128)
        when 40 then encrypt_rc4(user_password, owner_password || user_password,
                                 permissions, v: 2, r: 3, length: 40)
        else
          raise Pdfrb::EncryptionError,
                "unsupported key length: #{bits} (use 40, 128, or 256)"
        end
      end

      # Whether the document has an /Encrypt dict in the trailer.
      def encrypted?
        trailer = document.trailer
        !trailer.nil? && !trailer[:Encrypt].nil?
      end

      # Remove /Encrypt from the trailer (decrypt use case). Returns
      # self for chaining; use encrypted? to check the result.
      def decrypt!
        trailer = document.trailer
        if trailer && trailer[:Encrypt]
          if trailer.is_a?(Pdfrb::Model::Cos::Dictionary)
            trailer.value.delete(:Encrypt)
          else
            trailer.delete(:Encrypt)
          end
          document.config["encryption.handler"] = nil
          document.config["encryption.password"] = nil
        end
        self
      end

      # Compute the /P integer: all bits set minus the denied ones.
      def self.permission_bits(granted)
        base = -1
        PERMISSION_FLAGS.each do |name, bit|
          base &= ~bit unless granted.include?(name)
        end
        base
      end

      private

      def ensure_id!
        id0 = Digest::MD5.hexdigest(Time.now.to_s + rand.to_s)[0, 16]
        trailer = document.trailer
        if trailer.is_a?(Pdfrb::Model::Cos::Dictionary)
          trailer.value[:ID] = [id0.b, id0.b]
        else
          trailer[:ID] = [id0.b, id0.b]
        end
        id0.b
      end

      # RC4-based encryption for V2/V4 (40-bit or 128-bit).
      def encrypt_rc4(user_pw, owner_pw, permissions, v:, r:, length:)
        p_bits = self.class.permission_bits(permissions)
        id0 = ensure_id!

        o_entry = compute_o_entry(user_pw, owner_pw, r, length)
        key = Pdfrb::Encryption::PasswordVerification.derive_key_rc4(
          password: user_pw, o_entry: o_entry.b, p_flags: p_bits,
          id0: id0, revision: r, key_length_bits: length,
          encrypt_metadata: true
        )
        u_entry =
          if r == 2
            Pdfrb::Encryption::PasswordVerification.build_u_r2(key)
          else
            Pdfrb::Encryption::PasswordVerification.build_u_r3plus(
              file_key: key, id0: id0, revision: r
            )
          end

        register({ Filter: :Standard, V: v, R: r, Length: length,
                   P: p_bits, O: o_entry, U: u_entry },
                 user_password: user_pw)
      end

      # AES-256 R6 encryption for V5.
      def encrypt_v5(user_pw, owner_pw, permissions)
        p_bits = self.class.permission_bits(permissions)
        id0 = ensure_id!

        handler = Pdfrb::Encryption::StandardSecurityHandler.for_v5(
          user_password: user_pw, owner_password: owner_pw,
          permissions: p_bits, id: id0
        )
        dict = handler.encrypt_dict
        register({ Filter: :Standard, V: dict[:V], R: dict[:R],
                   Length: dict[:Length], P: p_bits,
                   O: dict[:O], U: dict[:U], UE: dict[:UE],
                   OE: dict[:OE], Perms: dict[:Perms] },
                 user_password: user_pw,
                 prebuilt_handler: handler)
      end

      # Compute the /O entry per Algorithm 3 (owner password hash).
      def compute_o_entry(user_pw, owner_pw, revision, length_bits)
        require "digest/md5"
        pv = Pdfrb::Encryption::PasswordVerification
        padded = pv.pad_password(owner_pw)
        digest = Digest::MD5.digest(padded)
        if revision >= 3
          50.times do
            digest = if length_bits >= 128
                       Digest::MD5.digest(digest[0, length_bits / 8])
                     else
                       Digest::MD5.digest(digest[0, 5])
                     end
          end
        end
        rc4 = Pdfrb::Encryption::RC4Impl.new(digest[0, length_bits / 8])
        o = rc4.process(pv.pad_password(user_pw))
        if revision >= 3
          19.downto(1) do |i|
            key = digest[0, length_bits / 8].bytes.map { |b| b ^ i }.pack("C*")
            o = Pdfrb::Encryption::RC4Impl.new(key).process(o)
          end
        end
        o
      end

      # Register the encrypt dict in the trailer + wire the handler.
      def register(encrypt_hash, user_password:, prebuilt_handler: nil)
        dict = document.add(encrypt_hash,
                            type: Pdfrb::Model::Type::EncryptionStandard)
        ref = dict.ref
        trailer = document.trailer
        if trailer.is_a?(Pdfrb::Model::Cos::Dictionary)
          trailer.value[:Encrypt] = ref
        else
          trailer[:Encrypt] = ref
        end

        handler = prebuilt_handler || begin
          h = Pdfrb::Encryption::StandardSecurityHandler.new(
            { Encrypt: encrypt_hash,
              ID: if trailer.is_a?(Pdfrb::Model::Cos::Dictionary)
                    trailer.value[:ID]
                  else
                    trailer[:ID]
                  end }
          )
          h.verify_user_password?(user_password)
          h
        end
        document.config["encryption.handler"] = handler
        document.config["encryption.password"] = user_password
        dict
      end
    end
  end
end
