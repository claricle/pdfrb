# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Color::ICCProfile do
  let(:minimal_icc) do
    # Build a minimal ICC profile header (128 bytes).
    # Only the fields we parse: profile size at offset 0, version at 8,
    # device class at 12, color space at 16, "acsp" signature at 36.
    header = "\x00" * 128
    # Profile size (offset 0, u32) = 128
    header[0, 4] = [128].pack("N")
    # Version (offset 8, u32) = 2.1.0 → 0x02100000
    header[8, 4] = [0x02100000].pack("N")
    # Device class (offset 12, 4 bytes ASCII) = "mntr" (monitor)
    header[12, 4] = "mntr"
    # Color space (offset 16, 4 bytes ASCII) = "RGB "
    header[16, 4] = "RGB "
    # Signature (offset 36, 4 bytes ASCII) = "acsp"
    header[36, 4] = "acsp"
    header.force_encoding(Encoding::BINARY)
  end

  it "parses ICC header metadata" do
    profile = described_class.new(minimal_icc)
    expect(profile.device_class).to eq("mntr")
    expect(profile.color_space).to eq("RGB ")
    expect(profile.component_count).to eq(3)
    expect(profile.version).to eq("2.1.0")
  end

  it "derives alternate color space from profile color space" do
    profile = described_class.new(minimal_icc)
    expect(profile.alternate).to eq(:DeviceRGB)
  end

  it "accepts explicit alternate override" do
    profile = described_class.new(minimal_icc, alternate: :DeviceCMYK)
    expect(profile.alternate).to eq(:DeviceCMYK)
  end

  it "validates signature" do
    profile = described_class.new(minimal_icc)
    expect(profile).to be_valid
  end

  it "detects invalid profile" do
    bad = "\x00" * 128
    profile = described_class.new(bad)
    expect(profile).not_to be_valid
  end

  it "handles CMYK profiles" do
    cmyk = minimal_icc.dup
    cmyk[16, 4] = "CMYK"
    profile = described_class.new(cmyk)
    expect(profile.component_count).to eq(4)
    expect(profile.alternate).to eq(:DeviceCMYK)
  end

  it "handles Gray profiles" do
    gray = minimal_icc.dup
    gray[16, 4] = "GRAY"
    profile = described_class.new(gray)
    expect(profile.component_count).to eq(1)
    expect(profile.alternate).to eq(:DeviceGray)
  end
end

RSpec.describe Pdfrb::Document::Colors do
  let(:minimal_icc) do
    header = "\x00" * 128
    header[0, 4] = [128].pack("N")
    header[8, 4] = [0x02100000].pack("N")
    header[12, 4] = "mntr"
    header[16, 4] = "RGB "
    header[36, 4] = "acsp"
    header.force_encoding(Encoding::BINARY)
  end

  let(:doc) do
    Pdfrb::Document.new.tap do |d|
      d.pages.add
    end
  end

  it "embeds an ICC profile as an indirect stream" do
    cs_array = doc.colors.embed_icc_profile(minimal_icc)

    expect(cs_array).to be_a(Pdfrb::Model::PdfArray)
    expect(cs_array[0]).to eq(:ICCBased)
    expect(cs_array[1]).to be_a(Pdfrb::Model::Reference)
  end

  it "produces a readable ICC stream after serialization round-trip" do
    cs_array = doc.colors.embed_icc_profile(minimal_icc)
    page = doc.pages.first

    doc.colors.register(page, cs_array)
    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    page2 = reparsed.pages.first
    resources = page2.value[:Resources]
    resources = resources.value if resources.is_a?(Pdfrb::Model::Cos::Dictionary)

    cs = resources[:ColorSpace]
    cs = cs.value if cs.is_a?(Pdfrb::Model::Cos::Dictionary)
    expect(cs[:CS1]).not_to be_nil
  end
end
