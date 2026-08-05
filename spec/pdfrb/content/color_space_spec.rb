# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Content::ColorSpace do
  describe "device color spaces" do
    it "registers DeviceGray" do
      expect(described_class::REGISTRY[:DeviceGray]).to eq(described_class::DeviceGray)
      expect(described_class::DeviceGray.components).to eq(1)
    end

    it "registers DeviceRGB" do
      expect(described_class::DeviceRGB.components).to eq(3)
    end

    it "registers DeviceCMYK" do
      expect(described_class::DeviceCMYK.components).to eq(4)
    end
  end

  describe "CIE-based color spaces" do
    it "creates CalGray" do
      cs = described_class::CalGray.new(white_point: [0.9505, 1.0, 1.089])
      expect(cs.white_point).to eq([0.9505, 1.0, 1.089])
    end

    it "creates CalRGB" do
      cs = described_class::CalRGB.new(white_point: [0.9505, 1.0, 1.089])
      expect(cs.components).to eq(3)
    end

    it "creates Lab" do
      cs = described_class::Lab.new(white_point: [0.9505, 1.0, 1.089])
      expect(cs.family).to eq(:Lab)
    end
  end

  describe "special color spaces" do
    it "creates Indexed" do
      cs = described_class::Indexed.new(base: :DeviceRGB, hival: 3, lookup: "\xFF\x00\x00".b)
      expect(cs.hival).to eq(3)
    end

    it "creates Separation" do
      cs = described_class::Separation.new(name: "PANTONE#20185",
                                           alternate_space: :DeviceCMYK,
                                           tint_transform: nil)
      expect(cs.name).to eq("PANTONE#20185")
    end

    it "creates DeviceN" do
      cs = described_class::DeviceN.new(names: %w[Cyan Magenta],
                                        alternate_space: :DeviceCMYK,
                                        tint_transform: nil)
      expect(cs.components).to eq(2)
    end

    it "creates Pattern" do
      cs = described_class::Pattern.new
      expect(cs.family).to eq(:Pattern)
    end
  end

  describe ".resolve" do
    it "returns registered class by name" do
      expect(described_class.resolve(:DeviceRGB)).to eq(described_class::DeviceRGB)
    end

    it "returns nil for unknown" do
      expect(described_class.resolve(:UnknownCS)).to be_nil
    end
  end
end
