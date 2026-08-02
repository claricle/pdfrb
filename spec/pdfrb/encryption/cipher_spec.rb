# frozen_string_literal: true

require "spec_helper"
require "digest/md5"

RSpec.describe Pdfrb::Encryption::RC4 do
  it "round-trips bytes" do
    key = "secret".b
    plain = "Hello, World!".b
    encrypted = described_class.new(key).encrypt(plain)
    decrypted = described_class.new(key).decrypt(encrypted)
    expect(decrypted).to eq(plain)
  end

  it "matches a known RC4 test vector" do
    # RFC 6229 test vector: Key=0102030405, plaintext=00..00, ciphertext...
    key = "\x01\x02\x03\x04\x05".b
    plain = "\x00" * 16
    encrypted = described_class.new(key).process(plain)
    expect(encrypted.bytes.first(5)).to eq([0xB2, 0x39, 0x63, 0x05, 0xF0])
  end
end

RSpec.describe Pdfrb::Encryption::AES do
  let(:aes) { described_class.new(key_size: 128, mode: :CBC) }
  let(:key) { "0123456789ABCDEF".b }
  let(:iv) { "FEDCBA9876543210".b }

  it "round-trips with a 16-byte key" do
    plain = "Hello, World!".b
    encrypted = aes.encrypt(plain, key, iv)
    decrypted = aes.decrypt(encrypted, key)
    expect(decrypted).to eq(plain)
  end
end

RSpec.describe Pdfrb::Encryption::PasswordVerification do
  describe ".pad_password" do
    it "pads short passwords to 32 bytes" do
      padded = described_class.pad_password("hi")
      expect(padded.bytesize).to eq(32)
    end

    it "truncates long passwords to 32 bytes" do
      padded = described_class.pad_password("a" * 100)
      expect(padded.bytesize).to eq(32)
    end
  end

  describe ".derive_key_rc4" do
    it "produces a key of the requested length" do
      key = described_class.derive_key_rc4(
        password: "user", o_entry: ("\x00" * 32).b,
        p_flags: -4, id0: "abcd".b, revision: 3,
        key_length_bits: 128, encrypt_metadata: true
      )
      expect(key.bytesize).to eq(16)
    end
  end
end
