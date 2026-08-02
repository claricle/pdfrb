# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Reference do
  it "stores oid and gen" do
    ref = described_class.new(5, 2)
    expect(ref.oid).to eq(5)
    expect(ref.gen).to eq(2)
  end

  it "defaults gen to 0" do
    expect(described_class.new(5).gen).to eq(0)
  end

  it "is frozen" do
    expect(described_class.new(1)).to be_frozen
  end

  describe "value equality" do
    it "is equal when oid/gen match" do
      expect(described_class.new(5, 0)).to eq(described_class.new(5, 0))
    end

    it "is unequal when gen differs" do
      expect(described_class.new(5, 0)).not_to eq(described_class.new(5, 1))
    end

    it "is unequal to a non-Reference" do
      expect(described_class.new(5)).not_to eq(5)
    end
  end

  it "hashes by (oid, gen) so it can be a hash key" do
    a = described_class.new(5, 0)
    b = described_class.new(5, 0)
    expect(a.hash).to eq(b.hash)
    expect({ a => 1 }[b]).to eq(1)
  end

  it "is comparable with <=> by (oid, gen)" do
    a = described_class.new(1, 0)
    b = described_class.new(2, 0)
    expect(a < b).to be(true)
    expect(b > a).to be(true)
  end

  it "serialises as '5 0 R'" do
    expect(described_class.new(5, 0).to_s).to eq("5 0 R")
  end
end
