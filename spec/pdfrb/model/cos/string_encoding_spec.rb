# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Cos::StringEncoding do
  describe ".decode_text" do
    it "passes through UTF-8 strings" do
      expect(described_class.decode_text("hello".encode("UTF-8"))).to eq("hello")
    end

    it "decodes a UTF-16BE BOM-prefixed string" do
      bom = "\xFE\xFF".b
      body = "hi".encode("UTF-16BE").force_encoding("BINARY")
      result = described_class.decode_text(bom + body)
      expect(result).to eq("hi")
      expect(result.encoding).to eq(Encoding::UTF_8)
    end

    it "decodes PDFDocEncoding high bytes (0xC3 -> U+221A per Appendix D.2)" do
      bytes = "\xC3".b
      expect(described_class.decode_text(bytes)).to eq("√") # √
    end
  end

  describe ".encode_text" do
    it "uses PDFDocEncoding when ASCII-only" do
      bytes = described_class.encode_text("hello")
      expect(bytes.encoding).to eq(Encoding::BINARY)
      expect(bytes).to eq("hello".b)
    end

    it "uses UTF-16BE BOM when chars fall outside PDFDocEncoding" do
      bytes = described_class.encode_text("日本語")
      expect(bytes.start_with?("\xFE\xFF".b)).to be(true)
    end
  end

  describe ".mark_binary" do
    it "produces an ASCII-8BIT frozen string" do
      s = described_class.mark_binary("abc")
      expect(s.encoding).to eq(Encoding::BINARY)
      expect(s).to be_frozen
    end
  end
end
