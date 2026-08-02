# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Rectangle do
  it "exposes llx/lly/urx/ury and width/height" do
    r = described_class.new(0, 0, 100, 200)
    expect(r.llx).to eq(0.0)
    expect(r.ury).to eq(200.0)
    expect(r.width).to eq(100.0)
    expect(r.height).to eq(200.0)
  end

  it "is frozen" do
    expect(described_class.new(0, 0, 1, 1)).to be_frozen
  end

  it "builds from an Array via from_array" do
    r = described_class.from_array([0, 1, 2, 3])
    expect(r.llx).to eq(0.0)
    expect(r.ury).to eq(3.0)
  end

  it "is value-equal" do
    a = described_class.new(0, 0, 1, 1)
    b = described_class.new(0, 0, 1, 1)
    expect(a).to eq(b)
    expect(a.hash).to eq(b.hash)
  end

  it "exposes left/right/top/bottom aliases" do
    r = described_class.new(1, 2, 3, 4)
    expect(r.left).to eq(1.0)
    expect(r.bottom).to eq(2.0)
    expect(r.right).to eq(3.0)
    expect(r.top).to eq(4.0)
  end
end
