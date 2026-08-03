# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Fonts do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  describe "standard fonts" do
    it "creates a font dict with encoding" do
      name = doc.fonts.add("Helvetica")
      expect(name).to eq(:F1)

      ref = doc.catalog.value[:Resources][:Font][name]
      font = doc.object(ref)
      expect(font[:Subtype]).to eq(:Type1)
      expect(font[:BaseFont]).to eq(:Helvetica)
      expect(font[:Encoding]).to eq(:WinAnsiEncoding)
    end

    it "creates a FontDescriptor with AFM metrics" do
      doc.fonts.add("Times-Roman")
      font_ref = doc.catalog.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)

      fd_ref = font.value[:FontDescriptor]
      expect(fd_ref).to be_a(Pdfrb::Model::Reference)

      fd = doc.object(fd_ref)
      expect(fd[:FontName]).to eq(:"Times-Roman")
      expect(fd[:FontBBox]).to be_an(Array)
    end

    it "caches font registrations" do
      name1 = doc.fonts.add("Courier")
      name2 = doc.fonts.add("Courier")
      expect(name1).to eq(name2)
    end

    it "assigns incrementing resource names" do
      f1 = doc.fonts.add("Helvetica")
      f2 = doc.fonts.add("Times-Roman")
      expect(f1).to eq(:F1)
      expect(f2).to eq(:F2)
    end

    it "does not set encoding for Symbol and ZapfDingbats" do
      doc.fonts.add("Symbol")
      font_ref = doc.catalog.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      expect(font[:Encoding]).to be_nil
    end
  end

  describe "text width measurement" do
    it "measures text width using AFM metrics" do
      width = doc.fonts.text_width("Hello", "Helvetica", size: 12)
      expect(width).to be_a(Float)
      expect(width).to be_positive
    end

    it "returns proportional width for different sizes" do
      w12 = doc.fonts.text_width("Test", "Helvetica", size: 12)
      w24 = doc.fonts.text_width("Test", "Helvetica", size: 24)
      expect(w24).to be_within(0.01).of(w12 * 2)
    end

    it "handles unknown fonts with fallback" do
      width = doc.fonts.text_width("Hi", "UnknownFont", size: 10)
      expect(width).to be_positive
    end
  end

  describe "TrueType embedding" do
    it "embeds a TrueType font from IO" do
      # Create a minimal TrueType-like header
      ttf_data = "OTTO#{"\x00" * 100}"
      io = StringIO.new(ttf_data)

      expect { doc.fonts.add(io) }.not_to raise_error
    end
  end
end

RSpec.describe Pdfrb::Document do
  it "syncs XMP to /Metadata stream on write" do
    doc = described_class.new
    doc.pages.add
    doc.info.title = "Test Title"

    io = StringIO.new
    doc.write(io: io)

    reparsed = described_class.new(io: StringIO.new(io.string))
    metadata_ref = reparsed.catalog.value[:Metadata]
    expect(metadata_ref).to be_a(Pdfrb::Model::Reference)

    metadata = reparsed.object(metadata_ref)
    expect(metadata[:Type]).to eq(:Metadata)
    expect(metadata[:Subtype]).to eq(:XML)
  end

  it "syncs layers on write" do
    doc = described_class.new
    doc.pages.add
    doc.layers.add("Background")
    # layers.sync! is called automatically by finalize_facades!

    io = StringIO.new
    doc.write(io: io)

    reparsed = described_class.new(io: StringIO.new(io.string))
    ocp = reparsed.catalog.value[:OCProperties]
    expect(ocp).not_to be_nil
  end

  it "does not create /Metadata when no XMP set" do
    doc = described_class.new
    doc.pages.add

    io = StringIO.new
    doc.write(io: io)

    reparsed = described_class.new(io: StringIO.new(io.string))
    expect(reparsed.catalog[:Metadata]).to be_nil
  end
end
