# frozen_string_literal: true

require "spec_helper"
require "zlib"

RSpec.describe Pdfrb::ImageLoader::JPEG do
  let(:doc) { Pdfrb::Document.new }

  it "parses a minimal JPEG and builds an Image XObject" do
    bytes = File.binread("/tmp/test.jpg")
    image = described_class.call(doc, bytes)
    expect(image).to be_a(Pdfrb::Model::Type::XObjectImage)
    expect(image[:Width]).to eq(2)
    expect(image[:Height]).to eq(1)
    expect(image[:BitsPerComponent]).to eq(8)
    expect(image[:ColorSpace]).to eq(:DeviceRGB)
    expect(image[:Filter]).to eq(:DCTDecode)
    expect(image.stream).to eq(bytes.b)
  end

  it "returns nil for non-JPEG bytes" do
    expect(described_class.call(doc, "not a jpeg".b)).to be_nil
  end
end

RSpec.describe Pdfrb::ImageLoader::PNG do
  let(:doc) { Pdfrb::Document.new }

  it "parses a minimal PNG and builds an Image XObject" do
    bytes = File.binread("/tmp/test.png")
    image = described_class.call(doc, bytes)
    expect(image).to be_a(Pdfrb::Model::Type::XObjectImage)
    expect(image[:Width]).to eq(2)
    expect(image[:Height]).to eq(2)
    expect(image[:BitsPerComponent]).to eq(8)
    expect(image[:Filter]).to eq(:FlateDecode)
    expect(image[:ColorSpace]).to eq(:DeviceRGB)
  end

  it "returns nil for non-PNG bytes" do
    expect(described_class.call(doc, "not a png".b)).to be_nil
  end
end

RSpec.describe Pdfrb::ImageLoader do
  let(:doc) { Pdfrb::Document.new }

  it "dispatches to JPEG for JPEG bytes" do
    bytes = File.binread("/tmp/test.jpg")
    image = described_class.load(doc, bytes)
    expect(image[:Filter]).to eq(:DCTDecode)
  end

  it "dispatches to PNG for PNG bytes" do
    bytes = File.binread("/tmp/test.png")
    image = described_class.load(doc, bytes)
    expect(image[:Filter]).to eq(:FlateDecode)
  end

  it "raises when no loader matches" do
    expect {
      described_class.load(doc, "garbage".b)
    }.to raise_error(Pdfrb::Error)
  end
end

RSpec.describe Pdfrb::Document::Images do
  it "adds an image via path and returns a resource name" do
    doc = Pdfrb::Document.new
    name = doc.images.add("/tmp/test.png")
    expect(name).to eq(:Im1)
    image = doc.images[name]
    expect(image[:Width]).to eq(2)
    expect(image[:Height]).to eq(2)
  end

  it "attaches the image to Catalog /Resources /XObject" do
    doc = Pdfrb::Document.new
    name = doc.images.add("/tmp/test.jpg")
    xobj = doc.catalog.value[:Resources][:XObject]
    expect(xobj[name]).to be_a(Pdfrb::Model::Reference)
  end
end
