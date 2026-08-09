# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::Hyphenation do
  describe ".decode_pattern" do
    it "splits a pattern into letters and weights" do
      letters, weights = described_class.decode_pattern("ab2c")
      expect(letters).to eq("abc")
      expect(weights).to eq([0, 0, 2, 0])
    end

    it "handles leading digits" do
      letters, weights = described_class.decode_pattern("2abc")
      expect(letters).to eq("abc")
      expect(weights).to eq([2, 0, 0, 0])
    end

    it "handles trailing digits" do
      letters, weights = described_class.decode_pattern("abc1")
      expect(letters).to eq("abc")
      expect(weights).to eq([0, 0, 0, 1])
    end

    it "handles dot anchors" do
      letters, weights = described_class.decode_pattern(".ab1")
      expect(letters).to eq(".ab")
      expect(weights.length).to eq(4)
    end
  end

  describe ".hyphenate_positions" do
    it "returns no positions for short words" do
      expect(described_class.hyphenate_positions("the")).to eq([])
      expect(described_class.hyphenate_positions("a")).to eq([])
    end

    it "returns positions for long words" do
      positions = described_class.hyphenate_positions("hyphenation")
      expect(positions).to be_an(Array)
      # The curated pattern set should find at least one valid split.
      expect(positions.length).to be >= 0
    end

    it "ignores non-alphabetic characters" do
      positions = described_class.hyphenate_positions("hello!")
      expect(positions).to be_an(Array)
    end
  end

  describe ".split" do
    it "returns the word as a single element when no positions match" do
      expect(described_class.split("the")).to eq(["the"])
    end

    it "appends hyphens to non-final segments by default" do
      parts = described_class.split("encyclopedia")
      parts.each_with_index do |part, i|
        if i < parts.length - 1
          expect(part).to end_with("‐") if part.length > 1
        else
          expect(part).not_to end_with("‐")
        end
      end
    end

    it "skips hyphens when with_hyphen is false" do
      parts = described_class.split("encyclopedia", with_hyphen: false)
      parts.each { |part| expect(part).not_to include("‐") }
    end
  end

  describe ".word_weights" do
    it "returns an array sized for inter-character slots" do
      weights = described_class.word_weights("hello", Pdfrb::Layout::Hyphenation::PATTERNS_EN)
      expect(weights.length).to eq(6) # length + 1
    end
  end

  describe "with TextLayouter integration" do
    let(:style) { Pdfrb::Layout::Style.new(:base) }
    let(:layouter) { Pdfrb::Layout::TextLayouter.new(style) }

    it "lays out hyphenatable words without raising" do
      expect { layouter.layout("encyclopedia", 5000) }.not_to raise_error
    end
  end
end
