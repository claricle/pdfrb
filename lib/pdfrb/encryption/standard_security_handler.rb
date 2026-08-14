# frozen_string_literal: true

require "openssl"
require "securerandom"

module Pdfrb
  module Encryption
    class StandardSecurityHandler
      PAD = String.new("\x28\xBF\x4E\x5E\x4E\x75\x8A\x41\x64\x00\x4E\x56\xFF\xFA\x01\x08" \
                       "\x2E\x2E\x00\xB6\xD0\x68\x3E\x80\x2F\x0C\xA9\xFE\x64\x53\x69\x7A",
                       encoding: Encoding::BINARY).freeze

      attr_reader :key, :key_length, :version, :revision, :permissions, :encrypt_dict

      # @param trailer_dict [Hash] must contain :Encrypt (the /Encrypt
      #   dict Hash) and optionally :ID (the trailer /ID array).
      # @param precomputed_key [String, nil] when supplied, skips
      #   password-based key derivation and uses this raw key. Used by
      #   .for_v5 to inject the freshly-generated file encryption key.
      def initialize(trailer_dict, precomputed_key: nil)
        @encrypt = trailer_dict[:Encrypt]
        @encrypt_dict = @encrypt
        @id = trailer_dict[:ID]
        @version = (@encrypt[:V] || 0).to_i
        @revision = (@encrypt[:R] || 3).to_i
        @key_length = (@encrypt[:Length] || 40).to_i / 8
        @permissions = (@encrypt[:P] || -1).to_i
        @key = precomputed_key
      end

      # Construct a write-side V5 (AES-256, R6) handler from a user
      # and owner password. Returns a StandardSecurityHandler whose
      # encrypt_dict is populated with /U, /O, /UE, /OE, /Perms ready
      # for inclusion in the trailer. The handler's key is set to the
      # freshly-generated file encryption key so #encrypt works.
      def self.for_v5(user_password:, owner_password:, permissions: -1,
                      id: SecureRandom.hex(16).b, key_length: 32)
        file_key = SecureRandom.random_bytes(key_length)

        u_validation_salt = V5Writer.random_salt
        u_key_salt = V5Writer.random_salt
        o_validation_salt = V5Writer.random_salt
        o_key_salt = V5Writer.random_salt

        u_entry = V5Writer.build_u_entry(password: user_password.to_s,
                                         validation_salt: u_validation_salt,
                                         key_salt: u_key_salt)
        o_entry = V5Writer.build_o_entry(owner_password: owner_password.to_s,
                                         user_password: user_password.to_s,
                                         validation_salt: o_validation_salt,
                                         key_salt: o_key_salt)

        u_intermediate = V5Writer.hash_v5(user_password.to_s, u_key_salt)
        ue = V5Writer.aes_ecb_encrypt(file_key, u_intermediate)

        o_intermediate = V5Writer.hash_v5(owner_password.to_s + user_password.to_s, o_key_salt)
        oe = V5Writer.aes_ecb_encrypt(file_key, o_intermediate)

        perms_plain = "#{[permissions & 0xFFFFFFFF, 0xFFFFFFFF].pack('VV')}T#{SecureRandom.random_bytes(7)}"

        encrypt_dict = {
          Filter: :Standard,
          V: 5,
          R: 6,
          Length: key_length * 8,
          P: permissions,
          U: u_entry,
          O: o_entry,
          UE: ue,
          OE: oe,
          Perms: V5Writer.aes_ecb_encrypt(perms_plain, file_key),
        }

        trailer = { Encrypt: encrypt_dict, ID: [id, id] }
        new(trailer, precomputed_key: file_key)
      end

      def verify_user_password?(password)
        return verify_user_password_v5?(password) if @version >= 5

        computed = compute_encryption_key(password)
        @key = computed
        verify_user_password_hash?(computed)
      end

      def verify_user_password_v5?(password)
        u_entry = @encrypt[:U] || "".b
        _hash, validation_salt, _key_salt = V5Writer.extract_v5_salts(u_entry)
        return false unless validation_salt

        candidate = V5Writer.hash_v5(password.to_s, validation_salt)
        stored_hash = u_entry.byteslice(0, 32)
        return false unless candidate[0, 32] == stored_hash

        # Password verified — derive and stash the file key so the
        # handler is immediately usable for decrypt/encrypt.
        @key = compute_encryption_key_v5(password)
        true
      end

      def compute_encryption_key(password)
        return compute_encryption_key_v5(password) if @version >= 5

        padded = pad_password(password)
        owner_hash = @encrypt[:O] || String.new("", encoding: Encoding::BINARY)
        perms = [@permissions].pack("V")
        id_first = id_bytes

        md5 = Digest::MD5.new
        md5.update(padded)
        md5.update(owner_hash)
        md5.update(perms)
        md5.update(id_first)

        if @revision >= 4
          md5.update(@encrypt[:UE] || "")
          md5.update(@encrypt[:Perms] ? [@encrypt[:Perms]].pack("N") : "")
        end

        hash = md5.digest

        if @revision >= 3
          50.times { hash = Digest::MD5.digest(hash[0, @key_length]) }
        end

        hash[0, @key_length]
      end

      # V5 key derivation: SHA-256 of (password + key_salt) gives an
      # intermediate hash. AES-ECB-decrypt /UE with the intermediate
      # to recover the file encryption key.
      def compute_encryption_key_v5(password)
        u_entry = @encrypt[:U] || "".b
        _hash, _vsalt, key_salt = V5Writer.extract_v5_salts(u_entry)
        return nil unless key_salt

        intermediate = V5Writer.hash_v5(password.to_s, key_salt)
        ue = @encrypt[:UE] || "".b
        return nil if ue.bytesize != 32

        V5Writer.aes_ecb_decrypt(ue, intermediate)
      end

      def compute_object_key(oid, gen)
        return compute_object_key_v5(oid, gen) if @version >= 5

        md5 = Digest::MD5.new
        md5.update(@key)
        md5.update([oid].pack("V"))
        md5.update([gen].pack("v"))

        if @version >= 4
          md5.update("\xAA")
        end

        md5.digest[0, [@key_length + 5, 16].min]
      end

      # V5 per-object key: SHA-256 of (file_key || oid_le32 || gen_le32).
      def compute_object_key_v5(oid, gen)
        Digest::SHA256.digest(@key + [oid].pack("V") + [gen].pack("V"))
      end

      def encrypt_data(data, oid, gen)
        return data unless @key

        obj_key = compute_object_key(oid, gen)

        if @version >= 4
          encrypt_aes_cbc(data, obj_key)
        else
          encrypt_rc4(data, obj_key)
        end
      end

      # Serializer-compatible alias for encrypt_data. The Serializer
      # calls encrypter.encrypt(payload, oid, gen) on string/stream
      # payloads during serialization.
      alias encrypt encrypt_data

      def decrypt_data(data, oid, gen)
        return data unless @key

        obj_key = compute_object_key(oid, gen)

        if @version >= 4
          decrypt_aes_cbc(data, obj_key)
        else
          decrypt_rc4(data, obj_key)
        end
      end

      private

      def pad_password(password)
        pw = password.to_s.encode(Encoding::BINARY)[0, 32]
        pw + PAD[pw.bytesize, 32 - pw.bytesize]
      end

      def id_bytes
        return String.new("", encoding: Encoding::BINARY) unless @id

        first = @id.is_a?(Array) ? @id[0] : @id
        first.to_s.encode(Encoding::BINARY)
      end

      def verify_user_password_hash?(key)
        return true if @revision < 3

        hash = compute_user_password_hash(key)
        stored = @encrypt[:U] || ""
        hash[0, 16] == stored[0, 16]
      end

      def compute_user_password_hash(key)
        md5 = Digest::MD5.new
        md5.update(PAD)
        md5.update(id_bytes)
        hash = md5.digest

        rc4 = RC4Impl.new(key)
        19.downto(1) do |i|
          xored_key = key.bytes.map { |b| b ^ i }.pack("C*")
          rc4 = RC4Impl.new(xored_key)
          hash = rc4.process(hash)
        end

        hash[0, 16]
      end

      def encrypt_rc4(data, key)
        RC4Impl.new(key).process(data)
      end

      def decrypt_rc4(data, key)
        RC4Impl.new(key).process(data)
      end

      def encrypt_aes_cbc(data, key)
        iv = OpenSSL::Random.random_bytes(16)
        cipher = OpenSSL::Cipher.new("aes-128-cbc")
        cipher.encrypt
        cipher.key = key[0, 16]
        cipher.iv = iv
        encrypted = cipher.update(data) + cipher.final
        iv + encrypted
      end

      def decrypt_aes_cbc(data, key)
        return data if data.bytesize < 16

        iv = data[0, 16]
        ciphertext = data[16..]
        decipher = OpenSSL::Cipher.new("aes-128-cbc")
        decipher.decrypt
        decipher.key = key[0, 16]
        decipher.iv = iv
        decipher.update(ciphertext) + decipher.final
      rescue OpenSSL::Cipher::CipherError
        data
      end
    end

    # Minimal RC4 implementation
    class RC4Impl
      def initialize(key)
        @s = (0..255).to_a
        j = 0
        key.bytes.each_with_index do |_b, i|
          j = (j + @s[i] + key.getbyte(i % key.bytesize)) & 0xFF
          @s[i], @s[j] = @s[j], @s[i]
        end
        @i = @j = 0
      end

      def process(data, _xor = nil)
        result = data.dup.force_encoding(Encoding::BINARY)
        result.bytes.each_with_index do |_b, idx|
          @i = (@i + 1) & 0xFF
          @j = (@j + @s[@i]) & 0xFF
          @s[@i], @s[@j] = @s[@j], @s[@i]
          k = @s[(@s[@i] + @s[@j]) & 0xFF]
          result.setbyte(idx, result.getbyte(idx) ^ k)
        end
        result
      end
    end
  end
end
