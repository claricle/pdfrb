# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::PdfArray do
  it "is enumerable" do
    arr = described_class.new([1, 2, 3])
    expect(arr.map { |x| x * 2 }).to eq([2, 4, 6])
  end

  it "supports indexed access" do
    arr = described_class.new([10, 20, 30])
    expect(arr[0]).to eq(10)
    expect(arr[-1]).to eq(30)
  end

  it "supports mutation via << and []=" do
    arr = described_class.new
    arr << 1
    arr << 2
    arr[0] = 99
    expect(arr.to_a).to eq([99, 2])
  end

  it "reports length and empty?" do
    expect(described_class.new([1, 2]).length).to eq(2)
    expect(described_class.new).to be_empty
  end

  it "compares with PdfArray and Array by value" do
    a = described_class.new([1, 2])
    expect(a).to eq(described_class.new([1, 2]))
    expect(a).to eq([1, 2])
  end

  it "to_a returns a copy" do
    arr = described_class.new([1, 2])
    copy = arr.to_a
    copy << 3
    expect(arr.to_a).to eq([1, 2])
  end
end
