# frozen_string_literal: true

require "spec_helper"
require "openssl"

RSpec.describe "Parity batch 10 deep specs" do
  describe Pdfrb::Content::Parser, "inline image (BI/ID/EI)" do
    let(:stream) do
      # Build the content stream byte-by-byte to avoid UTF-8
      # encoding issues with \x00\xFF in source literals.
      (+"").b.tap do |s|
        s << "q\n"
        s << "BI\n"
        s << "/W 2\n"
        s << "/H 2\n"
        s << "/CS /G\n"
        s << "/BPC 8\n"
        s << "ID\n"
        s << [0, 255, 255, 0].pack("C*")
        s << "\n"
        s << "EI\n"
        s << "Q\n"
      end
    end

    it "parses BI ... ID ... EI as a single InlineImage invocation" do
      parser = described_class.parse(stream)
      invocations = parser.each_invocation.to_a
      inline = invocations.find do |op, _|
        op == Pdfrb::Content::Operator::BeginInlineImage
      end
      expect(inline).not_to be_nil
    end

    it "expands BI abbreviation keys to full names" do
      parser = described_class.parse(stream)
      invocations = parser.each_invocation.to_a
      _op, operands = invocations.find do |o, _|
        o == Pdfrb::Content::Operator::BeginInlineImage
      end
      inline = operands.first
      expect(inline.width).to eq(2)
      expect(inline.height).to eq(2)
      expect(inline.header[:ColorSpace]).to eq(:G)
      expect(inline.bits_per_component).to eq(8)
    end

    it "extracts raw image bytes between ID and EI" do
      parser = described_class.parse(stream)
      invocations = parser.each_invocation.to_a
      _op, operands = invocations.find do |o, _|
        o == Pdfrb::Content::Operator::BeginInlineImage
      end
      inline = operands.first
      # Data includes the 4 pixel bytes (may have trailing separator).
      expect(inline.data).not_to be_empty
      expect(inline.data).to include([0].pack("C"))
    end

    it "handles streams without inline images unchanged" do
      stream = "BT\n/F1 12 Tf\n(Hello) Tj\nET\n"
      parser = described_class.parse(stream)
      invocations = parser.each_invocation.to_a
      expect(invocations).not_to be_empty
      inline_invocations = invocations.select do |op, _|
        op == Pdfrb::Content::Operator::BeginInlineImage
      end
      expect(inline_invocations).to be_empty
    end
  end

  describe Pdfrb::Encryption::PublicKeySecurityHandler do
    def generate_rsa_keypair(key_size: 2048)
      key = OpenSSL::PKey::RSA.generate(key_size)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse("/CN=pdfrb-test")
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.now
      cert.not_after = Time.now + (365 * 24 * 3600)
      cert.sign(key, OpenSSL::Digest.new("SHA256"))
      [key, cert]
    end

    it "builds recipients via OpenSSL::PKCS7" do
      _, cert = generate_rsa_keypair
      file_key = "X" * 32
      recipients = described_class.build_recipients(
        file_key: file_key, recipient_certs: [cert]
      )
      expect(recipients.length).to eq(1)
      expect(recipients.first).to be_a(String)
      expect(recipients.first.bytesize).to be > 100 # DER EnvelopedData
    end

    it "for_writer generates a random file key + recipients" do
      _key, cert = generate_rsa_keypair
      handler = described_class.for_writer(recipient_certs: [cert])
      expect(handler.file_key).not_to be_nil
      expect(handler.file_key.bytesize).to eq(32)
      expect(handler.recipients.length).to eq(1)
    end

    it "encrypts and decrypts round-trip per object" do
      key, cert = generate_rsa_keypair
      handler = described_class.for_writer(recipient_certs: [cert])
      plaintext = "Hello, public-key world!".b
      ciphertext = handler.encrypt_data(plaintext, 5, 0)
      expect(ciphertext).not_to eq(plaintext)

      # Build a reader handler that can decrypt with the recipient key.
      reader = described_class.new(
        recipients: handler.recipients,
        private_key: key,
        certificate: cert
      )
      decrypted = reader.decrypt_data(ciphertext, 5, 0)
      expect(decrypted).to eq(plaintext)
    end

    it "reports can_decrypt? only when key + cert + recipients all set" do
      h = described_class.new(recipients: ["x"])
      expect(h.can_decrypt?).to be false
    end
  end
end
