# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Font system completeness" do
  let(:arial_path) { "/System/Library/Fonts/Supplemental/Arial.ttf" }
  let(:arial_data) { File.binread(arial_path) if File.exist?(arial_path) }
  let(:ttf) { Pdfrb::Font::TrueType::File.new(arial_data) if arial_data }

  before { skip "Arial.ttf not found" unless File.exist?(arial_path) }

  describe Pdfrb::Font::TrueType::File do
    it "parses all table accessors" do
      expect(ttf.head).to be_a(Pdfrb::Font::TrueType::Head)
      expect(ttf.hhea).to be_a(Pdfrb::Font::TrueType::Hhea)
      expect(ttf.hmtx).to be_a(Pdfrb::Font::TrueType::Hmtx)
      expect(ttf.cmap).to be_a(Pdfrb::Font::TrueType::Cmap)
    end
  end

  describe Pdfrb::Font::TrueType::Maxp do
    it "reports glyph count" do
      maxp = described_class.new(ttf.maxp_table)
      expect(maxp.num_glyphs).to be > 100
    end
  end

  describe Pdfrb::Font::TrueType::Name do
    it "parses family name" do
      name = described_class.new(ttf.name_table)
      expect(name.family).to eq("Arial")
    end
  end

  describe Pdfrb::Font::TrueType::Wrapper do
    it "embeds a TrueType font" do
      doc = Pdfrb::Document.new
      font = described_class.embed(doc, arial_data, resource_name: :"F1")
      expect(font[:Subtype]).to eq(:TrueType)
      expect(font[:BaseFont]).to eq(:ArialMT)
    end
  end

  describe Pdfrb::Font::CMap::Writer do
    it "generates a valid CMap" do
      mapping = { 0x41 => 0x0041, 0x42 => 0x0042 }
      cmap = described_class.write(mapping)
      expect(cmap).to include("begincmap")
      expect(cmap).to include("endcmap")
      expect(cmap).to include("<41> <0041>")
    end
  end
end

RSpec.describe Pdfrb::FontLoader::Standard14 do
  it "loads Helvetica" do
    doc = Pdfrb::Document.new
    font = described_class.call(doc, "Helvetica")
    expect(font[:BaseFont]).to eq(:Helvetica)
  end

  it "returns nil for non-standard font" do
    doc = Pdfrb::Document.new
    expect(described_class.call(doc, "MyFont")).to be_nil
  end
end

RSpec.describe Pdfrb::FontLoader::VariantFromName do
  it "derives Helvetica-Bold from Helvetica+Bold" do
    doc = Pdfrb::Document.new
    font = described_class.call(doc, "Helvetica-Bold")
    expect(font[:BaseFont]).to eq(:"Helvetica-Bold")
  end
end
