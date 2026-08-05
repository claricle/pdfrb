# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TrueType table parsers" do
  let(:path) { "/System/Library/Fonts/Supplemental/Arial.ttf" }
  let(:data) { File.binread(path) }
  let(:ttf) { Pdfrb::Font::TrueType::File.new(data) }

  before { skip "Arial.ttf not found" unless File.exist?(path) }

  describe Pdfrb::Font::TrueType::Maxp do
    it "parses glyph count" do
      maxp = described_class.new(ttf.maxp_table)
      expect(maxp.num_glyphs).to be_positive
    end

    it "parses version 1.0 fields" do
      maxp = described_class.new(ttf.maxp_table)
      expect(maxp.max_points).to be_positive if maxp.version == 0x10000
    end
  end

  describe Pdfrb::Font::TrueType::Post do
    it "parses italic angle" do
      post = described_class.new(ttf.post_table)
      expect(post.italic_angle).to eq(0.0)
    end

    it "reports fixed pitch flag" do
      post = described_class.new(ttf.post_table)
      expect(post.is_fixed_pitch).to eq(0)
    end
  end

  describe Pdfrb::Font::TrueType::Name do
    it "parses font family" do
      name = described_class.new(ttf.name_table)
      expect(name.family).to eq("Arial")
    end

    it "parses PostScript name" do
      name = described_class.new(ttf.name_table)
      expect(name.ps_name).to eq("ArialMT")
    end
  end

  describe Pdfrb::Font::TrueType::Loca do
    it "has numGlyphs+1 offsets" do
      maxp = Pdfrb::Font::TrueType::Maxp.new(ttf.maxp_table)
      loca = described_class.new(ttf.loca_table, long_format: ttf.head.long_loca?, num_glyphs: maxp.num_glyphs)
      expect(loca.offsets.length).to eq(maxp.num_glyphs + 1)
    end

    it "returns glyph offset and length" do
      maxp = Pdfrb::Font::TrueType::Maxp.new(ttf.maxp_table)
      loca = described_class.new(ttf.loca_table, long_format: ttf.head.long_loca?, num_glyphs: maxp.num_glyphs)
      expect(loca.glyph_offset(0)).to be >= 0
      expect(loca.glyph_length(0)).to be >= 0
    end
  end

  describe Pdfrb::Font::TrueType::Glyf do
    subject(:glyf) { described_class.new(ttf.glyf_table, loca) }

    let(:maxp) { Pdfrb::Font::TrueType::Maxp.new(ttf.maxp_table) }
    let(:loca) { Pdfrb::Font::TrueType::Loca.new(ttf.loca_table, long_format: ttf.head.long_loca?, num_glyphs: maxp.num_glyphs) }

    it "parses glyph header for glyph 65 (A)" do
      hdr = glyf.glyph_header(65)
      expect(hdr[:number_of_contours]).to eq(1)
      expect(hdr[:x_min]).to be < hdr[:x_max]
    end

    it "detects composite glyphs" do
      maxp.num_glyphs.times do |i|
        next unless glyf.composite?(i)

        components = glyf.component_glyphs(i)
        expect(components).to be_an(Array)
        break
      end
    end
  end

  describe Pdfrb::Font::TrueType::Kern do
    it "initializes without error" do
      kern_data = ttf.kern_table
      skip "no kern table" unless kern_data
      kern = described_class.new(kern_data)
      expect(kern.pairs).to be_a(Hash)
    end
  end
end
