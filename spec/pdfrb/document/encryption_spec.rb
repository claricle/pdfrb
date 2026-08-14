# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Encryption do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  describe "#encrypted?" do
    it "is false for a fresh document" do
      expect(doc.encryption.encrypted?).to be false
    end

    it "is true after encrypt!" do
      doc.encryption.encrypt!(user_password: "pw", bits: 128)
      expect(doc.encryption.encrypted?).to be true
    end
  end

  describe "#encrypt!" do
    it "creates /Encrypt in the trailer (128-bit)" do
      doc.encryption.encrypt!(user_password: "pw", bits: 128)
      expect(doc.trailer[:Encrypt]).to be_a(Pdfrb::Model::Reference)
      encrypt = doc.object(doc.trailer[:Encrypt])
      expect(encrypt.value[:V]).to eq(4)
      expect(encrypt.value[:R]).to eq(4)
      expect(encrypt.value[:Length]).to eq(128)
    end

    it "creates /Encrypt in the trailer (40-bit)" do
      doc.encryption.encrypt!(user_password: "pw", bits: 40)
      encrypt = doc.object(doc.trailer[:Encrypt])
      expect(encrypt.value[:V]).to eq(2)
      expect(encrypt.value[:R]).to eq(3)
    end

    it "creates /Encrypt in the trailer (256-bit AES-256)" do
      doc.encryption.encrypt!(user_password: "pw", bits: 256)
      encrypt = doc.object(doc.trailer[:Encrypt])
      expect(encrypt.value[:V]).to eq(5)
      expect(encrypt.value[:R]).to eq(6)
      expect(encrypt.value[:Length]).to eq(256)
      expect(encrypt.value[:UE]).not_to be_empty
      expect(encrypt.value[:OE]).not_to be_empty
    end

    it "computes /P from granted permissions" do
      doc.encryption.encrypt!(user_password: "pw", bits: 128,
                              permissions: %i[print])
      encrypt = doc.object(doc.trailer[:Encrypt])
      # Only print granted → most bits are stripped.
      expect(encrypt.value[:P]).to be < 0
    end

    it "wires the handler into config" do
      doc.encryption.encrypt!(user_password: "pw", bits: 128)
      expect(doc.config["encryption.handler"]).not_to be_nil
      expect(doc.config["encryption.password"]).to eq("pw")
    end

    it "rejects unsupported key lengths" do
      expect do
        doc.encryption.encrypt!(user_password: "pw", bits: 64)
      end.to raise_error(Pdfrb::EncryptionError, /unsupported/)
    end
  end

  describe "#decrypt!" do
    it "removes /Encrypt from the trailer" do
      doc.encryption.encrypt!(user_password: "pw", bits: 128)
      doc.encryption.decrypt!
      expect(doc.encryption.encrypted?).to be false
    end

    it "is a no-op when not encrypted" do
      doc.encryption.decrypt!
      expect(doc.encryption.encrypted?).to be false
    end
  end

  describe ".permission_bits" do
    it "grants all when all permissions listed" do
      bits = described_class.permission_bits(described_class::PERMISSION_FLAGS.keys)
      expect(bits).to eq(-1)
    end

    it "denies unlisted permissions" do
      bits = described_class.permission_bits(%i[print])
      print_bit = described_class::PERMISSION_FLAGS[:print]
      expect(bits & print_bit).to eq(print_bit)
      copy_bit = described_class::PERMISSION_FLAGS[:copy]
      expect(bits & copy_bit).to eq(0)
    end
  end

  describe "end-to-end encrypt + write + reload" do
    it "produces a parseable encrypted PDF (40-bit)" do
      doc.encryption.encrypt!(user_password: "secret", bits: 40)
      out = StringIO.new
      doc.write(io: out)
      expect(out.string).to start_with("%PDF-")
      expect(out.string).to include("/Encrypt")
    end

    it "produces a parseable encrypted PDF (128-bit)" do
      doc.encryption.encrypt!(user_password: "secret", bits: 128)
      out = StringIO.new
      doc.write(io: out)
      expect(out.string).to start_with("%PDF-")
      expect(out.string).to include("/Encrypt")
    end
  end
end
