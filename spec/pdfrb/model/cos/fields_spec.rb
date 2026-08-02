# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Cos::Fields::Field do
  it "stores all options" do
    field = described_class.new(
      :Type,
      type: Symbol,
      required: true,
      default: :Foo,
      indirect: true,
      allowed_values: [:Foo, :Bar],
      version: "1.4"
    )
    expect(field.pdf_name).to eq(:Type)
    expect(field.type).to eq([Symbol])
    expect(field).to be_required
    expect(field.default).to eq(:Foo)
    expect(field.indirect).to be(true)
    expect(field.allowed_values).to eq([:Foo, :Bar])
    expect(field.version).to eq("1.4")
  end

  it "is frozen" do
    expect(described_class.new(:X, type: Integer)).to be_frozen
  end

  describe "#valid_value?" do
    let(:field) { described_class.new(:N, type: Integer) }

    it "accepts matching types" do
      expect(field.valid_value?(5)).to be(true)
    end

    it "rejects mismatched types" do
      expect(field.valid_value?("x")).to be(false)
    end
  end

  describe "Boolean type" do
    let(:field) { described_class.new(:B, type: Pdfrb::Model::Cos::Fields::Boolean) }

    it "accepts true and false" do
      expect(field.valid_value?(true)).to be(true)
      expect(field.valid_value?(false)).to be(true)
    end

    it "rejects other values" do
      expect(field.valid_value?(1)).to be(false)
    end
  end
end
