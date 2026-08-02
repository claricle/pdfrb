# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "pdfrb/source/helpers"

RSpec.describe Pdfrb::Source::Parser do
  def parse(src)
    Pdfrb::Source.parse_string(src)
  end

  it "parses an integer" do
    expect(parse("42")).to eq(42)
  end

  it "parses a real" do
    expect(parse("3.14")).to eq(3.14)
  end

  it "parses a name (decoded)" do
    expect(parse("/Type")).to eq(:Type)
  end

  it "parses a name with #-escapes" do
    expect(parse("/A#42B")).to eq(:ABB)
  end

  it "parses a literal string" do
    expect(parse("(Hello)")).to eq("Hello".b)
  end

  it "parses a hex string" do
    expect(parse("<48656c6c6f>")).to eq("Hello".b)
  end

  it "parses booleans and null" do
    expect(parse("true")).to be(true)
    expect(parse("false")).to be(false)
    expect(parse("null")).to be_nil
  end

  it "parses a Reference" do
    result = parse("5 0 R")
    expect(result).to be_a(Pdfrb::Model::Reference)
    expect(result.oid).to eq(5)
    expect(result.gen).to eq(0)
  end

  it "parses an empty array" do
    expect(parse("[]")).to eq([])
  end

  it "parses a non-empty array" do
    expect(parse("[1 2 3]")).to eq([1, 2, 3])
  end

  it "parses an empty dict" do
    expect(parse("<<>>")).to eq({})
  end

  it "parses a dict with multiple entries" do
    result = parse("<< /Type /Catalog /Pages 2 0 R /Count 0 >>")
    expect(result).to eq({ Type: :Catalog, Pages: Pdfrb::Model::Reference.new(2, 0), Count: 0 })
  end

  it "parses a nested dict" do
    result = parse("<< /A << /X 1 >> /B 2 >>")
    expect(result[:A]).to eq({ X: 1 })
    expect(result[:B]).to eq(2)
  end

  it "parses an indirect object" do
    src = "5 0 obj\n<< /Type /Catalog >>\nendobj\n"
    io = StringIO.new(src.b)
    parser = described_class.new(Pdfrb::Source::Tokenizer.new(io))
    obj = parser.parse_indirect_object
    expect(obj).to be_a(Pdfrb::Model::Cos::Dictionary)
    expect(obj.oid).to eq(5)
    expect(obj.gen).to eq(0)
    expect(obj[:Type]).to eq(:Catalog)
  end

  it "parses a stream object" do
    src = "1 0 obj\n<< /Length 5 >>\nstream\nhello\nendstream\nendobj\n"
    io = StringIO.new(src.b)
    parser = described_class.new(Pdfrb::Source::Tokenizer.new(io))
    obj = parser.parse_indirect_object
    expect(obj).to be_a(Pdfrb::Model::Cos::Stream)
    expect(obj.stream).to eq("hello".b)
  end
end
