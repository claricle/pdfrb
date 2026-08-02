# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "pdfrb/source/helpers"

# Property: for every COS value +v+, `parse(serialize(v)) == v`
# (modulo whitespace and float formatting).
RSpec.describe "COS round-trip property" do
  let(:serializer) { Pdfrb::Serializer.new }

  def round_trip(value)
    bytes = serializer.serialize(value)
    parsed = Pdfrb::Source.parse_string(bytes)
    [bytes, parsed]
  end

  SCALARS = [
    0, 1, -1, 42, 1_000_000,
    3.14, -2.5, 0.0, 1.5e10,
    true, false, nil,
    :Foo, :Bar, :"A#B", :"with-dash", :"with.dot",
    "hello", "with parens (a)", "with newline\n", "binary \xFF\xFE".b,
    Pdfrb::Model::Reference.new(5, 0),
    Pdfrb::Model::Reference.new(99, 2)
  ].freeze

  SCALARS.each do |value|
    it "round-trips scalar #{value.inspect}" do
      bytes, parsed = round_trip(value)
      case value
      when ::String
        expect(parsed.bytes).to eq(value.b.bytes)
      else
        expect(parsed).to eq(value)
      end
    end
  end

  it "round-trips an empty array" do
    _, parsed = round_trip([])
    expect(parsed).to eq([])
  end

  it "round-trips a flat array" do
    _, parsed = round_trip([1, 2, 3, :Foo, "x"])
    expect(parsed).to eq([1, 2, 3, :Foo, "x".b])
  end

  it "round-trips a nested array" do
    _, parsed = round_trip([1, [:a, :b], [2, [:c]]])
    expect(parsed).to eq([1, [:a, :b], [2, [:c]]])
  end

  it "round-trips an empty dict" do
    _, parsed = round_trip({})
    expect(parsed).to eq({})
  end

  it "round-trips a flat dict" do
    _, parsed = round_trip({ Type: :Catalog, Count: 0, Name: "hi" })
    expect(parsed).to eq({ Type: :Catalog, Count: 0, Name: "hi".b })
  end

  it "round-trips a deeply nested structure" do
    input = {
      Type: :Foo,
      Sub: [{ X: 1, Y: [2, 3] }, { Z: :bar }],
      Ref: Pdfrb::Model::Reference.new(7, 1)
    }
    _, parsed = round_trip(input)
    expect(parsed[:Type]).to eq(:Foo)
    expect(parsed[:Sub]).to be_an(Array)
    expect(parsed[:Sub][0][:X]).to eq(1)
    expect(parsed[:Sub][0][:Y]).to eq([2, 3])
    expect(parsed[:Ref]).to eq(Pdfrb::Model::Reference.new(7, 1))
  end
end
