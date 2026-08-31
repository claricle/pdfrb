# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "encrypted round trip" do
  def build_document(title:)
    Pdfrb::Document.new.tap do |d|
      font = d.fonts.add("Helvetica")
      2.times do |i|
        d.pages.add.canvas.text("Secret page #{i + 1}",
                                at: [72, 720], font: font, size: 12)
      end
      d.metadata[:Title] = title
    end
  end

  def write_and_reopen(doc, password:)
    io = StringIO.new
    doc.write(io: io)
    Pdfrb::Document.new(io: StringIO.new(io.string.b),
                        config: { "encryption.password" => password })
  end

  [256, 128, 40].each do |bits|
    describe "#{bits}-bit" do
      it "round-trips strings and content streams through decrypt" do
        doc = build_document(title: "confidential title")
        doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: bits)

        reopened = write_and_reopen(doc, password: "s3cret")

        expect(reopened.metadata[:Title]).to eq("confidential title")

        content = reopened.resolve(reopened.pages.first.value[:Contents])
        expect(content.stream).to include("Secret page 1")
      end

      it "decodes UTF-16 text strings back to UTF-8" do
        doc = build_document(title: "極秘文書 résumé")
        doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: bits)

        reopened = write_and_reopen(doc, password: "s3cret")

        expect(reopened.metadata[:Title]).to eq("極秘文書 résumé")
      end

      it "raises EncryptionError when the password does not verify" do
        doc = build_document(title: "confidential title")
        doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: bits)

        reopened = write_and_reopen(doc, password: "wrong")

        expect { reopened.metadata[:Title] }
          .to raise_error(Pdfrb::EncryptionError, /password/)
      end

      it "writes ciphertext for strings and stream payloads" do
        doc = build_document(title: "confidential title")
        doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: bits)
        io = StringIO.new
        doc.write(io: io)

        expect(io.string).not_to include("confidential title")
        expect(io.string).not_to include("Secret page 1")
        expect(io.string).to include("/Encrypt")
      end
    end
  end

  describe "V4 crypt filters" do
    it "128-bit /Encrypt declares AESV2 via CF/StmF/StrF" do
      doc = Pdfrb::Document.new
      doc.pages.add
      doc.encrypt!(user_password: "pw", bits: 128)
      io = StringIO.new
      doc.write(io: io)

      expect(io.string).to include("/StmF /StdCF")
      expect(io.string).to include("/StrF /StdCF")
      expect(io.string).to include("/CF")
      expect(io.string).to include("/AESV2")
    end

    it "handler round-trips with the cipher resolved from CFM" do
      handler = Pdfrb::Encryption::StandardSecurityHandler.new(
        { Encrypt: { V: 4, R: 4, CF: { StdCF: { CFM: :V2 } },
                     StmF: :StdCF, StrF: :StdCF },
          ID: ["id".b, "id".b] }
      )
      handler.verify_user_password?("pw") || handler.verify_user_password?("")
      encrypted = handler.encrypt_string("payload".b, 3, 0)
      expect(encrypted).not_to eq("payload".b)
      expect(handler.decrypt_string(encrypted, 3, 0)).to eq("payload".b)
    end

    it "V4 without crypt filters is Identity (passthrough)" do
      handler = Pdfrb::Encryption::StandardSecurityHandler.new(
        { Encrypt: { V: 4, R: 4 }, ID: ["id".b, "id".b] }
      )
      expect(handler.decrypt_string("raw".b, 1, 0)).to eq("raw".b)
      expect(handler.encrypt_stream("raw".b, 1, 0)).to eq("raw".b)
    end
  end

  describe "Pdfrb::Encryption::ValueStrings" do
    it "encrypt and decrypt are inverse over a value tree" do
      handler = Pdfrb::Encryption::StandardSecurityHandler
        .for_v5(user_password: "u", owner_password: "o")
      value = { A: "plain", B: [{ C: "nested".b }], D: 42, E: :Name }

      cipher = Pdfrb::Encryption::ValueStrings.encrypt(value, 7, 0, handler)
      expect(cipher[:A]).not_to eq("plain")
      expect(cipher[:D]).to eq(42)

      Pdfrb::Encryption::ValueStrings.decrypt!(cipher, 7, 0, handler)
      expect(cipher[:A]).to eq("plain".b)
      expect(cipher[:B][0][:C]).to eq("nested".b)
      expect(cipher[:E]).to eq(:Name)
    end
  end
end
