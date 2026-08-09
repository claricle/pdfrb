# frozen_string_literal: true

require "spec_helper"
require "openssl"

RSpec.describe Pdfrb::Encryption::StandardSecurityHandler do
  describe "V5 integration" do
    describe ".for_v5" do
      it "builds a handler with the right /Encrypt dict shape" do
        handler = described_class.for_v5(user_password: "user", owner_password: "owner")
        dict = handler.encrypt_dict
        expect(dict[:Filter]).to eq(:Standard)
        expect(dict[:V]).to eq(5)
        expect(dict[:R]).to eq(6)
        expect(dict[:Length]).to eq(256) # 32 bytes * 8
        expect(dict[:U].bytesize).to eq(48)
        expect(dict[:O].bytesize).to eq(48)
        expect(dict[:UE].bytesize).to eq(32)
        expect(dict[:OE].bytesize).to eq(32)
      end

      it "exposes the freshly-generated file encryption key" do
        handler = described_class.for_v5(user_password: "u", owner_password: "o")
        expect(handler.key).not_to be_nil
        expect(handler.key.bytesize).to eq(32)
        expect(handler.version).to eq(5)
        expect(handler.revision).to eq(6)
      end

      it "produces a per-object key of 32 bytes for V5" do
        handler = described_class.for_v5(user_password: "u", owner_password: "o")
        obj_key = handler.compute_object_key(7, 0)
        expect(obj_key.bytesize).to eq(32)
      end

      it "encrypts and decrypts round-trip per object" do
        handler = described_class.for_v5(user_password: "u", owner_password: "o")
        plaintext = "Hello, AES-256 world!".b
        ciphertext = handler.encrypt_data(plaintext, 10, 0)

        # Decrypt with a fresh handler that derives the key via
        # verify_user_password? (which sets @key on success).
        round_trip = described_class.new(
          { Encrypt: handler.encrypt_dict, ID: ["id".b, "id".b] }
        )
        expect(round_trip.verify_user_password?("u")).to be true
        expect(round_trip.key).not_to be_nil
        decrypted = round_trip.decrypt_data(ciphertext, 10, 0)
        expect(decrypted).to eq(plaintext)
      end

      it "verifies the user password via /U validation salt" do
        handler = described_class.for_v5(user_password: "secret", owner_password: "boss")
        dict = handler.encrypt_dict
        verifier = described_class.new({ Encrypt: dict, ID: ["id".b, "id".b] })
        expect(verifier.verify_user_password_v5?("secret")).to be true
        expect(verifier.verify_user_password_v5?("wrong")).to be false
      end

      it "produces different keys for different passwords" do
        h1 = described_class.for_v5(user_password: "alpha", owner_password: "x")
        h2 = described_class.for_v5(user_password: "beta", owner_password: "x")
        expect(h1.key).not_to eq(h2.key)
      end
    end
  end

  describe Pdfrb::Encryption::PublicKeySecurityHandler do
    it "is registered for Adobe.PPKLite filter" do
      expect(Pdfrb::Encryption::SecurityHandler.lookup("Adobe.PPKLite")).to eq(described_class)
    end
  end
end
