# frozen_string_literal: true

require "spec_helper"
require "openssl"
require "stringio"

RSpec.describe Pdfrb::DigitalSignature::Signing do
  let(:cert_key) do
    key = OpenSSL::PKey::RSA.generate(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test Signer/O=Pdfrb")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now - 3600
    cert.not_after = Time.now + 3600
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    [cert, key]
  end

  let(:doc) do
    Pdfrb::Document.new.tap do |d|
      font = d.fonts.add("Helvetica")
      d.pages.add.canvas.text("Sign me", at: [72, 720], font: font, size: 12)
    end
  end

  it "produces valid PDF bytes" do
    cert, key = cert_key
    signed = described_class.sign(doc, cert: cert, key: key)

    expect(signed).to start_with("%PDF-")
    expect(signed).to include("%%EOF")
  end

  it "embeds a PKCS#7 signature" do
    cert, key = cert_key
    signed = described_class.sign(doc, cert: cert, key: key)

    # /Contents is hex-encoded. DER PKCS#7 starts with 0x30 (ASN.1 SEQUENCE),
    # so the first two hex characters after '<' should be "30".
    # Search for "/Contents <" to skip page objects' /Contents references.
    contents_marker = "/Contents <"
    ck_idx = signed.index(contents_marker)
    expect(ck_idx).to be_positive

    hex_start = ck_idx + contents_marker.bytesize
    expect(signed[hex_start, 2]).to eq("30")
  end

  it "includes /ByteRange" do
    cert, key = cert_key
    signed = described_class.sign(doc, cert: cert, key: key)
    expect(signed).to include("/ByteRange")
  end

  it "includes signer metadata" do
    cert, key = cert_key
    signed = described_class.sign(doc, cert: cert, key: key, reason: "Approval")
    expect(signed).to include("/Reason")
    expect(signed).to include("Approval")
  end
end

RSpec.describe Pdfrb::DigitalSignature::Verification do
  let(:cert_key) do
    key = OpenSSL::PKey::RSA.generate(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = OpenSSL::X509::Name.parse("/CN=Test Signer/O=Pdfrb")
    cert.issuer = cert.subject
    cert.public_key = key.public_key
    cert.not_before = Time.now - 3600
    cert.not_after = Time.now + 3600
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    [cert, key]
  end

  it "verifies a self-signed document" do
    cert, key = cert_key
    doc = Pdfrb::Document.new.tap do |d|
      d.pages.add
    end

    signed = Pdfrb::DigitalSignature::Signing.sign(doc, cert: cert, key: key)
    results = described_class.verify(signed, trusted_certs: [cert])

    expect(results).not_to be_empty
    expect(results.first.valid?).to be true
  end

  it "detects tampered content" do
    cert, key = cert_key
    doc = Pdfrb::Document.new.tap do |d|
      d.pages.add
    end

    signed = Pdfrb::DigitalSignature::Signing.sign(doc, cert: cert, key: key)

    # Tamper: flip a byte in the /M timestamp inside the sig dict.
    # This is within the signed byte range but doesn't break PDF structure.
    m_idx = signed.index("(D:")
    tampered = signed.dup
    tampered.setbyte(m_idx + 3, tampered.getbyte(m_idx + 3) ^ 0x01)

    results = described_class.verify(tampered, trusted_certs: [cert])
    expect(results.first.valid?).to be false
  end

  it "returns empty array for unsigned PDF" do
    doc = Pdfrb::Document.new
    doc.pages.add
    io = StringIO.new
    doc.write(io: io)

    results = described_class.verify(io.string)
    expect(results).to be_empty
  end
end
