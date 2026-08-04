# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Content::ColorSpace do
  it "has 10 registered color spaces" do
    expect(described_class.families.length).to be >= 10
  end

  it "resolves DeviceRGB" do
    expect(described_class.resolve(:DeviceRGB)).to eq(described_class::DeviceRGB)
  end

  it "DeviceRGB has 3 components" do
    expect(described_class::DeviceRGB.components).to eq(3)
  end
end

RSpec.describe Pdfrb::Content::TransformationMatrix do
  it "is identity by default" do
    expect(described_class.new.identity?).to be true
  end

  it "translates correctly" do
    m = described_class.new.translate(100, 200)
    expect(m.e).to eq(100.0)
    expect(m.f).to eq(200.0)
  end

  it "scales correctly" do
    m = described_class.new.scale(2.5)
    expect(m.a).to eq(2.5)
    expect(m.d).to eq(2.5)
  end

  it "is immutable" do
    expect(described_class.new).to be_frozen
  end
end

RSpec.describe Pdfrb::Content::SmartTextExtractor do
  it "extracts text from a page" do
    doc = Pdfrb::Document.new.tap { |d| d.pages.add }
    results = described_class.extract(doc)
    expect(results).to be_an(Array)
    expect(results.length).to eq(1)
  end
end
