# frozen_string_literal: true

require "openssl"

module Pdfrb
  module Encryption
    class StandardSecurityHandler
      PAD = String.new("\x28\xBF\x4E\x5E\x4E\x75\x8A\x41\x64\x00\x4E\x56\xFF\xFA\x01\x08" \
                       "\x2E\x2E\x00\xB6\xD0\x68\x3E\x80\x2F\x0C\xA9\xFE\x64\x53\x69\x7A",
                       encoding: Encoding::BINARY).freeze

      attr_reader :key, :key_length, :version, :revision, :permissions

      def initialize(trailer_dict)
        @encrypt = trailer_dict[:Encrypt]
        @id = trailer_dict[:ID]
        @version = (@encrypt[:V] || 0).to_i
        @revision = (@encrypt[:R] || 3).to_i
        @key_length = (@encrypt[:Length] || 40).to_i / 8
        @permissions = (@encrypt[:P] || -1).to_i
        @key = nil
      end

      def verify_user_password(password)
        computed = compute_encryption_key(password)
        @key = computed
        verify_user_password_hash(computed)
      end

      def compute_encryption_key(password)
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

      def compute_object_key(oid, gen)
        md5 = Digest::MD5.new
        md5.update(@key)
        md5.update([oid].pack("V"))
        md5.update([gen].pack("v"))

        if @version >= 4
          md5.update("\xAA")
        end

        md5.digest[0, [@key_length + 5, 16].min]
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

      def verify_user_password_hash(key)
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
        20.times { |i| hash = rc4.process(hash, key ^ i) }

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
        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
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
        decipher = OpenSSL::Cipher::AES.new(128, :CBC)
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
