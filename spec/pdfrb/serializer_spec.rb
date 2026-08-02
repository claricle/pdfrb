# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "pdfrb/source/helpers"

RSpec.describe Pdfrb::Serializer do
  let(:s) { described_class.new }

  it "serialises integers" do
    expect(s.serialize(42)).to eq("42")
    expect(s.serialize(-5)).to eq("-5")
  end

  it "serialises reals" do
    expect(s.serialize(3.14)).to eq("3.14")
    expect(s.serialize(2.0)).to eq("2")
  end

  it "serialises booleans and null" do
    expect(s.serialize(true)).to eq("true")
    expect(s.serialize(false)).to eq("false")
    expect(s.serialize(nil)).to eq("null")
  end

  it "serialises names" do
    expect(s.serialize(:Foo)).to eq("/Foo")
    expect(s.serialize(:"A#B")).to eq("/A#23B")
  end

  it "serialises ASCII text strings" do
    expect(s.serialize("hello".encode("UTF-8"))).to eq("(hello)")
  end

  it "escapes string special chars" do
    expect(s.serialize("a(b)c".encode("UTF-8"))).to eq("(a\\(b\\)c)")
  end

  it "serialises References as 'oid gen R'" do
    expect(s.serialize(Pdfrb::Model::Reference.new(5, 0))).to eq("5 0 R")
  end

  it "serialises arrays" do
    expect(s.serialize([1, 2, 3])).to eq("[1 2 3]")
  end

  it "serialises dicts" do
    out = s.serialize({ Type: :Catalog, Count: 0 })
    expect(out).to include("/Type", "/Catalog", "/Count", "0")
  end

  it "serialises Rectangle as 4-number array" do
    rect = Pdfrb::Model::Rectangle.new(0, 0, 100, 200)
    expect(s.serialize(rect)).to eq("[0 0 100 200]")
  end

  describe "indirect-object serialization" do
    it "frames an indirect dict with obj/endobj" do
      obj = Pdfrb::Model::Cos::Dictionary.new({ Type: :Foo }, oid: 1, gen: 0)
      out = s.serialize_indirect(obj)
      expect(out).to start_with("1 0 obj\n")
      expect(out).to end_with("endobj\n")
      expect(out).to include("/Type /Foo")
    end

    it "frames a stream with /Length set automatically" do
      obj = Pdfrb::Model::Cos::Stream.new({ Type: :XRef },
                                          stream: "hello".b, oid: 1, gen: 0)
      out = s.serialize_indirect(obj)
      expect(out).to include("/Length 5")
      expect(out).to include("stream\nhello\nendstream")
    end
  end
end
