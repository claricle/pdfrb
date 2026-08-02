# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Font::CMap::Writer do
  let(:cid_system_info) do
    { registry: "Adobe", ordering: "Identity", supplement: 0 }
  end

  describe "round-trip through Parser" do
    it "writes a CMap that the Parser reads back" do
      mapping = { 65 => "A", 66 => "B", 67 => "C" }
      writer = described_class.new(
        cmap_name: "Test-UCS2",
        cid_system_info: cid_system_info,
        mapping: mapping
      )
      cmap_text = writer.to_s

      parsed = Pdfrb::Font::CMap::Parser.parse(cmap_text)
      expect(parsed.decode(65)).to eq("A")
      expect(parsed.decode(66)).to eq("B")
      expect(parsed.decode(67)).to eq("C")
    end

    it "handles BMP Unicode characters" do
      mapping = { 0x20 => " ", 0x41 => "A", 0x2014 => "—" }
      writer = described_class.new(
        cmap_name: "BMP-UCS2",
        cid_system_info: cid_system_info,
        mapping: mapping
      )
      parsed = Pdfrb::Font::CMap::Parser.parse(writer.to_s)
      expect(parsed.decode(0x20)).to eq(" ")
      expect(parsed.decode(0x41)).to eq("A")
      expect(parsed.decode(0x2014)).to eq("—")
    end

    it "handles supplementary Unicode (surrogate pairs)" do
      # U+1F600 (😀) → surrogate pair D83D DE00
      mapping = { 1 => "\u{1F600}" }
      writer = described_class.new(
        cmap_name: "Supp-UCS2",
        cid_system_info: cid_system_info,
        mapping: mapping
      )
      cmap_text = writer.to_s
      # The hex should contain "D83DDE00"
      expect(cmap_text).to include("D83DDE00")

      parsed = Pdfrb::Font::CMap::Parser.parse(cmap_text)
      expect(parsed.decode(1)).to eq("\u{1F600}")
    end
  end

  describe "1-byte codespacerange" do
    it "emits <00> <FF> for code_size 1" do
      writer = described_class.new(
        cmap_name: "OneByte",
        cid_system_info: cid_system_info,
        mapping: { 65 => "A" },
        code_size: 1
      )
      expect(writer.to_s).to include("<00> <FF>")
      expect(writer.to_s).not_to include("<0000> <FFFF>")
    end
  end

  describe "chunking" do
    it "splits bfchar into sections of ≤100 entries" do
      mapping = (1..250).to_h { |i| [i, i.chr] }
      writer = described_class.new(
        cmap_name: "Chunked",
        cid_system_info: cid_system_info,
        mapping: mapping
      )
      text = writer.to_s
      bfchar_count = text.scan("beginbfchar").length
      expect(bfchar_count).to be >= 3 # 250 / 100 = 3 sections
    end
  end

  describe "empty mapping" do
    it "emits valid CMap with no bfchar section" do
      writer = described_class.new(
        cmap_name: "Empty",
        cid_system_info: cid_system_info,
        mapping: {}
      )
      text = writer.to_s
      expect(text).to include("begincmap")
      expect(text).to include("endcmap")
      expect(text).not_to include("beginbfchar")
    end
  end

  describe "multi-codepoint Unicode" do
    it "emits ligatures as multiple hex pairs" do
      mapping = { 10 => "fi" }
      writer = described_class.new(
        cmap_name: "Ligature",
        cid_system_info: cid_system_info,
        mapping: mapping
      )
      # 'f' = 0066, 'i' = 0069
      expect(writer.to_s).to include("00660069")
    end
  end
end
