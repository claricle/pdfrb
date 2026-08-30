# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::PdfVersion do
  describe ".compare" do
    it "orders versions numerically, not lexically" do
      expect(described_class.compare("1.10", "1.9")).to eq(1)
    end

    it "returns 0 for equal versions" do
      expect(described_class.compare("1.7", "1.7")).to eq(0)
    end

    it "returns -1 for earlier versions" do
      expect(described_class.compare("1.4", "2.0")).to eq(-1)
    end

    it "handles differing component counts" do
      expect(described_class.compare("1.4", "1.4.1")).to eq(-1)
    end

    it "coerces non-strings" do
      expect(described_class.compare(2, "1.7")).to eq(1)
    end
  end

  describe ".at_least?" do
    it "is true when the version meets the minimum" do
      expect(described_class.at_least?("1.7", "1.4")).to be(true)
    end

    it "is false when the version is earlier" do
      expect(described_class.at_least?("1.3", "1.4")).to be(false)
    end
  end
end
