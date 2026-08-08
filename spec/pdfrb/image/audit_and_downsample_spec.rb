# frozen_string_literal: true

require "spec_helper"
require "zlib"
require "stringio"

RSpec.describe Pdfrb::Image::Audit do
  let(:doc) { Pdfrb::Document.new }

  def add_image(width:, height:, color_space: :DeviceRGB, filter: :FlateDecode,
                bpc: 8, stream: "")
    image = doc.add(
      { Type: :XObject, Subtype: :Image, Width: width, Height: height,
        BitsPerComponent: bpc, ColorSpace: color_space, Filter: filter,
        Length: stream.bytesize },
      type: Pdfrb::Model::Cos::Stream
    )
    image.stream = stream
    image
  end

  it "lists every image XObject" do
    add_image(width: 100, height: 50, stream: "abc")
    add_image(width: 200, height: 100, stream: "def")
    expect(described_class.all(doc).length).to eq(2)
  end

  it "excludes non-image XObjects" do
    doc.add({ Type: :XObject, Subtype: :Form, BBox: [0, 0, 1, 1] },
            type: Pdfrb::Model::Cos::Stream)
    add_image(width: 10, height: 10, stream: "x")
    expect(described_class.all(doc).length).to eq(1)
  end

  it "extracts width, height, bpc, color space, filter" do
    add_image(width: 640, height: 480, color_space: :DeviceGray,
              filter: :DCTDecode, bpc: 8, stream: "img")
    info = described_class.all(doc).first
    expect(info.width).to eq(640)
    expect(info.height).to eq(480)
    expect(info.color_space).to eq(:DeviceGray)
    expect(info.filter_name).to eq(:DCTDecode)
    expect(info.bits_per_component).to eq(8)
  end

  it "computes decoded bytesize for known geometry" do
    add_image(width: 10, height: 10, color_space: :DeviceRGB,
              bpc: 8, stream: "x" * 300)
    info = described_class.all(doc).first
    expect(info.decoded_bytesize).to eq(300)
  end

  it "channels_for returns 1 for gray, 3 for RGB, 4 for CMYK" do
    expect(described_class.channels_for(:DeviceGray)).to eq(1)
    expect(described_class.channels_for(:DeviceRGB)).to eq(3)
    expect(described_class.channels_for(:DeviceCMYK)).to eq(4)
  end

  it "oversized filter selects images above the pixel threshold" do
    add_image(width: 1000, height: 1000, stream: "big")
    add_image(width: 50, height: 50, stream: "small")
    big = described_class.oversized(doc, target_pixels: 100_000)
    expect(big.length).to eq(1)
    expect(big.first.width).to eq(1000)
  end

  it "captures SMask oid when present" do
    smask = doc.add({ Type: :XObject, Subtype: :Image, Width: 1, Height: 1,
                      BitsPerComponent: 8, ColorSpace: :DeviceGray },
                    type: Pdfrb::Model::Cos::Stream)
    image = add_image(width: 2, height: 2, stream: "xx")
    image.value[:SMask] = Pdfrb::Model::Reference.new(smask.oid, 0)
    info = described_class.all(doc).find { |i| i.oid == image.oid }
    expect(info.smask_oid).to eq(smask.oid)
  end
end

RSpec.describe Pdfrb::Image::Downsampler do
  let(:doc) { Pdfrb::Document.new }

  def build_image(width:, height:, color_space: :DeviceRGB, predictor: nil)
    bytes_per_pixel = color_space == :DeviceGray ? 1 : 3
    raw = ("A".."Z").to_a.join * ((width * height * bytes_per_pixel / 26) + 1)
    raw = raw.byteslice(0, width * height * bytes_per_pixel)
    dict = {
      Type: :XObject, Subtype: :Image,
      Width: width, Height: height,
      BitsPerComponent: 8, ColorSpace: color_space,
      Filter: :FlateDecode
    }
    if predictor
      dict[:DecodeParms] = { Predictor: predictor, Columns: width,
                             Colors: bytes_per_pixel, BitsPerComponent: 8 }
      payload = +""
      height.times do |row|
        offset = row * width * bytes_per_pixel
        payload << "\x00".b
        payload << raw.byteslice(offset, width * bytes_per_pixel)
      end
      encoded = Zlib::Deflate.deflate(payload)
    else
      encoded = Zlib::Deflate.deflate(raw)
    end
    dict[:Length] = encoded.bytesize
    image = doc.add(dict, type: Pdfrb::Model::Cos::Stream)
    image.stream = encoded
    [image, raw]
  end

  it "downsamples a 4x4 image to 2x2 by factor 2" do
    image, = build_image(width: 4, height: 4)
    changed = described_class.downsample!(image, factor: 2)
    expect(changed).not_to be_nil
    expect(image.value[:Width]).to eq(2)
    expect(image.value[:Height]).to eq(2)
  end

  it "preserves Filter and DecodeParms shape" do
    image, = build_image(width: 4, height: 4, predictor: 15)
    described_class.downsample!(image, factor: 2)
    expect(image.value[:Filter]).to eq(:FlateDecode)
    expect(image.value[:DecodeParms]).to be_a(Hash)
  end

  it "returns nil when factor is below 2" do
    image, = build_image(width: 4, height: 4)
    expect(described_class.downsample!(image, factor: 1)).to be_nil
  end

  it "returns nil for DCTDecode (JPEG) images" do
    image = doc.add(
      { Type: :XObject, Subtype: :Image, Width: 10, Height: 10,
        BitsPerComponent: 8, ColorSpace: :DeviceRGB, Filter: :DCTDecode },
      type: Pdfrb::Model::Cos::Stream
    )
    image.stream = "jpeg-bytes"
    expect(described_class.eligible?(image)).to be(false)
  end

  it "returns nil for Indexed (palette) images" do
    image = doc.add(
      { Type: :XObject, Subtype: :Image, Width: 10, Height: 10,
        BitsPerComponent: 8, ColorSpace: :Indexed,
        Filter: :FlateDecode },
      type: Pdfrb::Model::Cos::Stream
    )
    image.stream = "x" * 100
    expect(described_class.eligible?(image)).to be(false)
  end

  it "produces re-loadable output" do
    image, = build_image(width: 8, height: 8)
    described_class.downsample!(image, factor: 2)

    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    images = Pdfrb::Image::Audit.all(reloaded)
    expect(images.length).to eq(1)
    expect(images.first.width).to eq(4)
    expect(images.first.height).to eq(4)
  end
end

RSpec.describe Pdfrb::Task::Optimize do
  describe "image downsampling" do
    it "downsamples eligible images and shrinks the output" do
      doc = Pdfrb::Document.new
      doc.pages.add

      # Build a 16x16 RGB image with a predictor
      w = 16
      h = 16
      bytes_per_pixel = 3
      raw = (0..255).cycle.first(w * h * bytes_per_pixel)
        .pack("C*")
      payload = +""
      h.times do |row|
        offset = row * w * bytes_per_pixel
        payload << "\x00".b
        payload << raw.byteslice(offset, w * bytes_per_pixel)
      end
      encoded = Zlib::Deflate.deflate(payload)
      image = doc.add(
        { Type: :XObject, Subtype: :Image, Width: w, Height: h,
          BitsPerComponent: 8, ColorSpace: :DeviceRGB,
          Filter: :FlateDecode,
          DecodeParms: { Predictor: 15, Columns: w, Colors: 3,
                         BitsPerComponent: 8 },
          Length: encoded.bytesize },
        type: Pdfrb::Model::Cos::Stream
      )
      image.stream = encoded

      expect(described_class.downsample_images!(doc, factor: 2)).to eq(1)
      expect(image.value[:Width]).to eq(8)
      expect(image.value[:Height]).to eq(8)
    end

    it "skips JPEG images" do
      doc = Pdfrb::Document.new
      doc.pages.add
      image = doc.add(
        { Type: :XObject, Subtype: :Image, Width: 100, Height: 100,
          BitsPerComponent: 8, ColorSpace: :DeviceRGB, Filter: :DCTDecode },
        type: Pdfrb::Model::Cos::Stream
      )
      image.stream = "jpeg-bytes"

      expect(described_class.downsample_images!(doc, factor: 2)).to eq(0)
      expect(image.value[:Width]).to eq(100)
    end
  end
end
