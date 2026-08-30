# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Writer do
  let(:doc) { Pdfrb::Document.new }
  let(:io) { StringIO.new }

  it "writes a valid PDF header" do
    described_class.write(doc, io)
    io.rewind
    header = io.gets
    expect(header).to start_with("%PDF-1.4")
    binary_marker = io.gets
    expect(binary_marker).to start_with("%\xE2\xE3\xCF\xD3".b)
  end

  it "writes a trailer with %%EOF" do
    described_class.write(doc, io)
    io.rewind
    body = io.read
    expect(body).to end_with("%%EOF\n")
    expect(body).to include("startxref")
    expect(body).to include("/Root")
  end

  it "writes an xref section with the Catalog object" do
    described_class.write(doc, io)
    io.rewind
    body = io.read
    expect(body).to include("xref")
    expect(body).to include("/Type /Catalog")
    expect(body).to include("/Type /Pages")
  end

  describe ".serializer_for encryption handling" do
    def encrypted_doc
      Pdfrb::Document.new.tap do |d|
        d.pages.add
        handler = Pdfrb::Encryption::StandardSecurityHandler
          .for_v5(user_password: "s3cret", owner_password: "s3cret")
        encrypt_dict = d.add(handler.encrypt_dict,
                             type: Pdfrb::Model::Cos::Dictionary)
        d.trailer[:Encrypt] = encrypt_dict.ref
        d.trailer[:ID] = ["id0id0id0id0id0".b, "id0id0id0id0id0".b]
        d.metadata[:Title] = "topsecret title"
        d
      end
    end

    it "encrypts string payloads when the password verifies" do
      doc = encrypted_doc
      doc.config["encryption.password"] = "s3cret"
      out = StringIO.new
      described_class.write(doc, out)

      body = out.string
      expect(body).not_to include("topsecret title")
      expect(body).to include("/Encrypt")
    end

    it "raises EncryptionError when the password does not verify" do
      doc = encrypted_doc
      doc.config["encryption.password"] = "wrong"
      out = StringIO.new

      expect { described_class.write(doc, out) }
        .to raise_error(Pdfrb::EncryptionError, /password/)
    end
  end
end

RSpec.describe "end-to-end Document write/read" do
  it "round-trips an empty doc through write -> read" do
    src = Pdfrb::Document.new
    out = StringIO.new
    Pdfrb::Writer.write(src, out)

    out.rewind
    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.catalog[:Type]).to eq(:Catalog)
    pages_ref = dest.catalog.value[:Pages]
    pages = dest.object(pages_ref)
    expect(pages[:Count]).to eq(0)
  end
end
