# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Matrix do
  it "is identity by default" do
    m = described_class.identity
    expect(m).to be_identity
  end

  it "is frozen" do
    expect(described_class.new).to be_frozen
  end

  describe "factories" do
    it "translate" do
      m = described_class.translate(10, 20)
      expect(m.transform_point(0, 0)).to eq([10.0, 20.0])
    end

    it "scale" do
      m = described_class.scale(2, 3)
      expect(m.transform_point(1, 1)).to eq([2.0, 3.0])
    end

    it "rotate by 90deg" do
      m = described_class.rotate(Math::PI / 2)
      x, y = m.transform_point(1, 0)
      expect(x).to be_within(0.0001).of(0.0)
      expect(y).to be_within(0.0001).of(1.0)
    end
  end

  describe "composition" do
    it "translates after scaling" do
      sc = described_class.scale(2)
      tr = described_class.translate(10, 10)
      combined = tr * sc
      expect(combined.transform_point(5, 5)).to eq([20.0, 20.0])
    end
  end

  it "is value-equal" do
    a = described_class.translate(1, 2)
    b = described_class.translate(1, 2)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end
end
