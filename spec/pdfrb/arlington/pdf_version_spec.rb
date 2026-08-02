# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Arlington::PdfVersion do
  it "parses a canonical version" do
    v = described_class.new("1.7")
    expect(v.major).to eq(1)
    expect(v.minor).to eq(7)
    expect(v.to_s).to eq("1.7")
  end

  it "is frozen" do
    expect(described_class.new("1.0")).to be_frozen
  end

  describe "comparison" do
    it "orders versions correctly" do
      expect(described_class.new("1.4")).to be < described_class.new("1.7")
      expect(described_class.new("1.7")).to be < described_class.new("2.0")
    end

    it "is equal to itself" do
      expect(described_class.new("1.7")).to eq(described_class.new("1.7"))
    end
  end

  describe ".from_tsv_cell" do
    it "parses a plain version" do
      expect(described_class.from_tsv_cell("1.7").to_s).to eq("1.7")
    end

    it "parses fn:Extension(ISO_19005_3,1.7)" do
      v = described_class.from_tsv_cell("fn:Extension(ISO_19005_3,1.7)")
      expect(v.to_s).to eq("1.7")
      expect(v.extensions).to include("ISO_19005_3")
    end

    it "returns nil for empty input" do
      expect(described_class.from_tsv_cell("")).to be_nil
      expect(described_class.from_tsv_cell(nil)).to be_nil
    end
  end

  describe "#since?" do
    it "is true for older-or-equal" do
      expect(described_class.new("2.0").since?(described_class.new("1.7"))).to be(true)
    end
  end
end
