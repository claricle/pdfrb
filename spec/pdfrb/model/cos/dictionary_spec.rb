# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Cos::Dictionary do
  let(:doc) { Pdfrb::Document.new }

  it "wraps a Hash" do
    d = described_class.new({ Type: :Catalog, Pages: nil })
    expect(d[:Type]).to eq(:Catalog)
  end

  it "rejects non-Hash values" do
    expect { described_class.new("not a hash") }.to raise_error(ArgumentError)
  end

  it "enforces Symbol keys" do
    d = described_class.new
    expect { d["foo"] = 1 }.to raise_error(ArgumentError)
  end

  describe "field declaration" do
    subject(:klass) do
      Class.new(described_class) do
        define_field :Type, type: Symbol, required: true, default: :Foo
        define_field :Count, type: Integer, default: 0
      end
    end

    it "exposes declared fields" do
      expect(klass.field(:Type)).to be_required
      expect(klass.field(:Count).default).to eq(0)
    end

    it "applies required-with-default on construction" do
      instance = klass.new({}, document: doc)
      expect(instance.value[:Type]).to eq(:Foo)
    end

    it "does not overwrite an explicit value with the default" do
      instance = klass.new({ Type: :Bar }, document: doc)
      expect(instance.value[:Type]).to eq(:Bar)
    end

    it "iterates fields via each_field" do
      names = klass.each_field.map { |n, _| n }
      expect(names).to include(:Type, :Count)
    end
  end

  describe "[]" do
    let(:klass) do
      Class.new(described_class) do
        define_field :Type, type: Symbol, required: true, default: :Foo
      end
    end

    it "returns the raw value when no converter applies" do
      d = klass.new({ Type: :Bar }, document: doc)
      expect(d[:Type]).to eq(:Bar)
    end

    it "returns the default when missing" do
      d = klass.new({}, document: doc)
      expect(d[:Type]).to eq(:Foo)
    end

    it "returns nil when absent and no default" do
      d = klass.new({}, document: doc)
      expect(d[:Missing]).to be_nil
    end
  end

  describe "type registry" do
    it "registers and looks up types" do
      klass = Class.new(described_class)
      described_class.register_type(:MyType, klass)
      expect(described_class.lookup_type(:MyType)).to be(klass)
    end
  end

  describe "#each / #each_raw" do
    it "yields each key with processed value via each" do
      d = described_class.new({ A: 1, B: 2 }, document: doc)
      pairs = d.each.to_a
      expect(pairs).to include([:A, 1], [:B, 2])
    end

    it "yields raw values via each_raw" do
      d = described_class.new({ A: 1 }, document: doc)
      expect(d.each_raw.to_a).to eq([[:A, 1]])
    end
  end

  describe "validate" do
    subject(:klass) do
      Class.new(described_class) do
        define_field :Type, type: Symbol, required: true
        define_field :Count, type: Integer, allowed_values: [1, 2, 3]
      end
    end

    it "flags missing required fields" do
      d = klass.new({}, document: doc)
      msgs = d.validate.to_a
      expect(msgs.any? { |m, _| m.include?("Required field Type") }).to be(true)
    end

    it "flags disallowed values" do
      d = klass.new({ Type: :Foo, Count: 99 }, document: doc)
      msgs = d.validate.to_a
      expect(msgs.any? { |m, _| m.include?("disallowed value") }).to be(true)
    end

    it "passes silently when valid" do
      d = klass.new({ Type: :Foo, Count: 2 }, document: doc)
      expect(d.validate.to_a).to be_empty
    end
  end
end
