# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Object do
  let(:doc) { Pdfrb::Document.new }

  it "wraps a value with oid/gen/document" do
    obj = described_class.new("hello", oid: 5, gen: 2, document: doc)
    expect(obj.value).to eq("hello")
    expect(obj.oid).to eq(5)
    expect(obj.gen).to eq(2)
    expect(obj.document).to be(doc)
  end

  it "defaults oid/gen to 0 (direct)" do
    obj = described_class.new(:symbol)
    expect(obj.oid).to eq(0)
    expect(obj.gen).to eq(0)
    expect(obj).not_to be_indirect
  end

  it "is indirect when oid > 0" do
    expect(described_class.new("x", oid: 1)).to be_indirect
  end

  it "is not must_be_indirect? by default" do
    expect(described_class.new("x")).not_to be_must_be_indirect
  end

  it "deref is a no-op pass-through" do
    obj = described_class.new(42)
    expect(obj.deref).to be(obj)
  end

  describe "define_type / pdf_type" do
    it "exposes a statically declared /Type value" do
      klass = Class.new(described_class) { define_type :Catalog }
      expect(klass.pdf_type).to eq(:Catalog)
      expect(klass.new({}).pdf_type).to eq(:Catalog)
    end

    it "falls back to nil when no /Type is declared" do
      expect(described_class.new({}).pdf_type).to be_nil
    end

    it "reads /Type from a Hash value when no static type" do
      obj = described_class.new({ Type: :Foo })
      expect(obj.pdf_type).to eq(:Foo)
    end
  end

  describe "equality" do
    it "compares direct objects by value" do
      a = described_class.new(42)
      b = described_class.new(42)
      expect(a).to eq(b)
    end

    it "compares indirect objects by identity" do
      a = described_class.new(42, oid: 1)
      b = described_class.new(42, oid: 1)
      expect(a).not_to eq(b)
      expect(a).to eq(a)
    end
  end
end
