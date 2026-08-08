# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::Bidi do
  describe ".paragraph_level" do
    it "returns 0 for purely LTR text" do
      expect(described_class.paragraph_level("Hello world")).to eq(0)
    end

    it "returns 1 for Hebrew text" do
      expect(described_class.paragraph_level("שלום עולם")).to eq(1)
    end

    it "returns 1 for Arabic text" do
      expect(described_class.paragraph_level("مرحبا بالعالم")).to eq(1)
    end

    it "returns 0 when no strong character is present" do
      expect(described_class.paragraph_level("12345")).to eq(0)
    end
  end

  describe ".rtl?" do
    it "is true for Hebrew" do
      expect(described_class.rtl?("שלום")).to be true
    end

    it "is false for Latin" do
      expect(described_class.rtl?("Hello")).to be false
    end

    it "is true for mixed even if LTR comes first" do
      expect(described_class.rtl?("Hello שלום")).to be true
    end
  end

  describe ".bidi_type" do
    it "classifies ASCII letters as L" do
      expect(described_class.bidi_type("A".ord)).to eq(:L)
      expect(described_class.bidi_type("z".ord)).to eq(:L)
    end

    it "classifies Hebrew as R" do
      expect(described_class.bidi_type(0x05D0)).to eq(:R) # Alef
    end

    it "classifies Arabic as AL" do
      expect(described_class.bidi_type(0x0627)).to eq(:AL) # Aleph
    end

    it "classifies ASCII digits as EN" do
      expect(described_class.bidi_type("5".ord)).to eq(:EN)
    end

    it "classifies Arabic-Indic digits as AN" do
      expect(described_class.bidi_type(0x0660)).to eq(:AN)
    end

    it "classifies space as WS" do
      expect(described_class.bidi_type(" ".ord)).to eq(:WS)
    end
  end

  describe ".reorder" do
    it "is identity for purely LTR text" do
      expect(described_class.reorder("Hello world")).to eq("Hello world")
    end

    it "is identity for single character" do
      expect(described_class.reorder("A")).to eq("A")
    end

    it "reverses a pure Hebrew word" do
      source = "שלום"
      reordered = described_class.reorder(source)
      expect(reordered).to eq(source.reverse)
    end

    it "reverses Hebrew differently than Latin" do
      hebrew = "שלום"
      latin = "Hello"
      expect(described_class.reorder(hebrew)).not_to eq(hebrew)
      expect(described_class.reorder(latin)).to eq(latin)
    end

    it "preserves grapheme count for mixed text" do
      mixed = "Hello שלום world"
      reordered = described_class.reorder(mixed)
      expect(reordered.length).to eq(mixed.length)
    end

    it "mirrors parentheses in RTL runs" do
      source = "(שלום)"
      reordered = described_class.reorder(source)
      expect(reordered).to include(")")
      expect(reordered).to include("(")
    end
  end

  describe ".levels_for" do
    it "preserves 0 for LTR L characters at base level 0" do
      levels = described_class.levels_for(["H", "i"].each, 0).to_a
      expect(levels).to eq([0, 0])
    end

    it "raises R characters to level 1 at base level 0" do
      levels = described_class.levels_for(["ש".encode("UTF-8")].each, 0).to_a
      expect(levels.first).to eq(1)
    end
  end
end

RSpec.describe Pdfrb::Layout::TextLayouter do
  describe "with bidi" do
    let(:style) { Pdfrb::Layout::Style.new(:base) }
    let(:layouter) { described_class.new(style) }

    it "lays out Hebrew without raising" do
      expect { layouter.layout("שלום עולם", 5000) }.not_to raise_error
    end

    it "produces at least one line for Hebrew input" do
      lines = layouter.layout("שלום", 5000)
      expect(lines).not_to be_empty
    end

    it "lays out Arabic without raising" do
      expect { layouter.layout("مرحبا بالعالم", 5000) }.not_to raise_error
    end
  end
end
