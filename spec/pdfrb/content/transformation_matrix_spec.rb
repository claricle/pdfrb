# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Content::TransformationMatrix do
  it "starts as identity" do
    m = described_class.new
    expect(m.identity?).to be true
  end

  it "translates" do
    m = described_class.new.translate(10, 20)
    expect(m.e).to eq(10.0)
    expect(m.f).to eq(20.0)
  end

  it "scales" do
    m = described_class.new.scale(2, 3)
    expect(m.a).to eq(2.0)
    expect(m.d).to eq(3.0)
  end

  it "rotates 90 degrees" do
    m = described_class.new.rotate(Math::PI / 2)
    expect(m.a).to be_within(0.001).of(0.0)
    expect(m.b).to be_within(0.001).of(1.0)
  end

  it "multiplies matrices" do
    m1 = described_class.new.translate(10, 20)
    m2 = described_class.new.scale(2, 2)
    result = m1.multiply(m2)
    expect(result.e).to eq(20.0)
    expect(result.f).to eq(40.0)
  end

  it "converts to array" do
    m = described_class.new(1, 2, 3, 4, 5, 6)
    expect(m.to_a).to eq([1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
  end

  it "is frozen" do
    expect(described_class.new).to be_frozen
  end
end
