# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Cos::NameEncoding do
  describe ".encode" do
    it "emits a / prefix" do
      expect(described_class.encode(:Foo)).to eq("/Foo")
    end

    it "escapes the # delimiter" do
      expect(described_class.encode(:"A#B")).to eq("/A#23B")
    end

    it "escapes whitespace and delimiters" do
      expect(described_class.encode(:"A B")).to eq("/A#20B")
      expect(described_class.encode(:'< A >')).to eq("/#3C#20A#20#3E")
    end

    it "raises if not a symbol" do
      expect { described_class.encode("Foo") }.to raise_error(ArgumentError)
    end
  end

  describe ".decode" do
    it "strips the / prefix" do
      expect(described_class.decode("/Foo")).to eq(:Foo)
    end

    it "decodes #xx escapes" do
      expect(described_class.decode("/A#42B")).to eq(:ABB) # 0x42 = 'B'
    end

    it "tolerates a missing /" do
      expect(described_class.decode("Foo")).to eq(:Foo)
    end
  end

  it "round-trips" do
    sym = :Hello_World_123
    expect(described_class.decode(described_class.encode(sym))).to eq(sym)
  end
end
