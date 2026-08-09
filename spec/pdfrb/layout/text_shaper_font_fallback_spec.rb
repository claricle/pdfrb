# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::TextShaper do
  describe "cluster-aware default" do
    it "groups base + combining mark into a single cluster" do
      run = described_class.shape("é", size: 12) # é as e + combining acute
      expect(run.cluster_starts.length).to eq(1)
      expect(run.codepoints).to eq([0x65, 0x301])
      expect(run.advances).to eq([6.0, 0.0]) # combining mark advances 0
    end

    it "treats each ASCII letter as its own cluster" do
      run = described_class.shape("Hi", size: 12)
      expect(run.cluster_starts.length).to eq(2)
      expect(run.cluster_starts).to eq([0, 1])
    end

    it "marks CJK codepoints as wide (advance size * 0.6)" do
      run = described_class.shape("漢", size: 12)
      expect(run.advances.first).to be_within(0.01).of(12 * 0.6)
    end

    it "exposes cluster index per codepoint" do
      run = described_class.shape("ab́c", size: 12)
      # a, b, combining-mark, c → 3 clusters: [a], [b+mark], [c]
      expect(run.clusters).to eq([0, 1, 1, 2])
    end

    it "delegates to a registered implementation" do
      shim = Module.new do
        def self.shape(text, **)
          Pdfrb::Layout::TextShaper::ShapedRun.new(
            codepoints: text.to_s.codepoints.to_a,
            clusters: [], advances: [], cluster_starts: []
          )
        end
      end
      original = described_class.implementation
      described_class.implementation = shim
      run = described_class.shape("Hi")
      expect(run.cluster_starts).to eq([])
    ensure
      described_class.implementation = original
    end
  end
end

RSpec.describe Pdfrb::Layout::FontFallback do
  describe "AFM-aware coverage" do
    it "covers Latin-1 accented letters in Helvetica" do
      fb = described_class.new
      expect(fb.covers?("Helvetica", 0xE9)).to be true # é
      expect(fb.covers?("Helvetica", 0xE8)).to be true # è
    end

    it "covers Greek alpha in Symbol" do
      fb = described_class.new
      expect(fb.covers?("Symbol", 0x3B1)).to be true
    end

    it "does NOT cover CJK in Standard 14 fonts" do
      fb = described_class.new
      expect(fb.covers?("Helvetica", 0x6F22)).to be false
    end

    it "picks Symbol for Greek when Helvetica is primary" do
      fb = described_class.new
      expect(fb.pick(0x3B1, primary: "Helvetica")).to eq("Symbol")
    end

    it "returns nil when no font covers the codepoint" do
      fb = described_class.new(chain: ["Helvetica"])
      expect(fb.pick(0x6F22, primary: "Helvetica")).to be_nil
    end

    it "segments mixed Latin + Greek text" do
      fb = described_class.new
      segs = fb.segment("Hi α", primary: "Helvetica")
      fonts = segs.map(&:first).uniq
      expect(fonts).to include("Helvetica", "Symbol")
    end
  end
end
