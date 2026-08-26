# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "zlib"

RSpec.describe Pdfrb::Content::InlineImage do
  def parse(content)
    Pdfrb::Content::Parser.parse(content).each_invocation.to_a
      .find { |op, _| op.name == "BI" }
      .last.first
  end

  it "exposes geometry and expands color-space abbreviations" do
    image = parse("BI\n/W 4 /H 2 /BPC 8 /CS /RGB\nID x\nEI\n")
    expect(image.width).to eq(4)
    expect(image.height).to eq(2)
    expect(image.bits_per_component).to eq(8)
    expect(image.color_space).to eq(:DeviceRGB)
    expect(image.components).to eq(3)
    expect(image.expected_decoded_size).to eq(4 * 3 * 2)
  end

  it "expands gray and marks image masks" do
    gray = parse("BI\n/W 2 /H 2 /BPC 8 /CS /G\nID x\nEI\n")
    expect(gray.color_space).to eq(:DeviceGray)
    expect(gray.components).to eq(1)

    mask = parse("BI\n/W 8 /H 8 /IM 1\nID x\nEI\n")
    expect(mask).to be_image_mask
    expect(mask.expected_decoded_size).to be_nil
  end

  it "returns raw data when no filter is declared" do
    image = parse("BI\n/W 1 /H 1 /CS /G /BPC 8\nID \x80\nEI\n")
    expect(image.filters).to eq([])
    expect(image.decoded_data).to eq("\x80".b)
  end

  it "decodes ASCIIHex payloads (filter abbreviation /AHx)" do
    image = parse("BI\n/W 2 /H 1 /CS /G /BPC 8 /F /AHx\nID <00FF80FF>\nEI\n")
    expect(image.filters).to eq([:ASCIIHexDecode])
    expect(image.decoded_data).to eq([0, 255, 128, 255].pack("C*"))
  end

  it "decodes Flate payloads (filter abbreviation /Fl)" do
    pixels = (0...64).map { |i| (i * 4) % 256 }.pack("C*")
    content = +"BI\n/W 8 /H 8 /CS /G /BPC 8 /F /Fl\nID\n"
    content << Zlib::Deflate.deflate(pixels)
    content << "\nEI\n"
    image = parse(content)
    expect(image.filters).to eq([:FlateDecode])
    expect(image.decoded_data).to eq(pixels)
    expect(image.expected_decoded_size).to eq(64)
  end

  it "decodes ASCII85 payloads (filter abbreviation /A85)" do
    encoded = Pdfrb::Filter.apply(
      [1, 2, 3, 4].pack("C*"), filters: [:ASCII85Decode], parms: [],
                               direction: :encode
    )
    image = parse("BI\n/W 4 /H 1 /CS /G /BPC 8 /F /A85\nID #{encoded}\nEI\n")
    expect(image.filters).to eq([:ASCII85Decode])
    expect(image.decoded_data).to eq([1, 2, 3, 4].pack("C*"))
  end

  it "carries the full filter chain when given as an array" do
    image = parse("BI\n/W 1 /H 1 /CS /G /BPC 8 /F [/AHx]\nID <FF>\nEI\n")
    expect(image.filters).to eq([:ASCIIHexDecode])
    expect(image.decoded_data).to eq("\xFF".b)
  end
end
