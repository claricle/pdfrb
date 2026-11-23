# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"

RSpec.describe Pdfrb::Document::Fonts do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  describe "standard fonts" do
    it "creates a font dict with encoding" do
      name = doc.fonts.add("Helvetica")
      expect(name).to eq(:F1)

      ref = doc.pages.pages_root.value[:Resources][:Font][name]
      font = doc.object(ref)
      expect(font[:Subtype]).to eq(:Type1)
      expect(font[:BaseFont]).to eq(:Helvetica)
      expect(font[:Encoding]).to eq(:WinAnsiEncoding)
    end

    it "creates a FontDescriptor with AFM metrics" do
      doc.fonts.add("Times-Roman")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
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
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
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

  describe "PostScript name extraction (Issue #63)" do
    # Synthesised well-formed sfnt bytes: a real table directory plus a
    # real name table carrying nameID 6, so the extraction path runs
    # identically on any machine (the specs below previously pointed at
    # absolute paths under ~/Library/Fonts and skipped everywhere else).

    def name_table(ps_name)
      str = ps_name.encode(Encoding::UTF_16BE).b
      [0, 1, 6 + 12].pack("n3") +
        [3, 1, 0x409, 6, str.bytesize, 0].pack("n6") + str
    end

    def sfnt_bytes(version, ps_name)
      Pdfrb::Font::Sfnt.rebuild(version.b, [["name", name_table(ps_name)]])
    end

    def font_names(doc)
      doc.fonts.each.map(&:first)
    end

    it "extracts PS name when adding from file path" do
      Tempfile.create(["ps-name", ".ttf"]) do |f|
        f.binmode
        f.write(sfnt_bytes("\x00\x01\x00\x00", "RiboseLogoType-Alternate"))
        f.close

        doc.fonts.add(f.path)
        expect(font_names(doc)).to include(include("RiboseLogoType-Alternate"))
      end
    end

    it "extracts PS name from an OTF (OTTO) container added via IO" do
      data = sfnt_bytes("OTTO", "Posterama1901-Light")
      doc.fonts.add(StringIO.new(data))
      expect(font_names(doc)).to include(include("Posterama1901-Light"))
    end

    it "falls back to EmbeddedFont<bytesize> when name table is absent" do
      ttf_data = "OTTO#{"\x00" * 100}"
      io = StringIO.new(ttf_data)
      doc.fonts.add(io)
      expect(font_names(doc).first).to match(/EmbeddedFont\d+\z/)
    end

    it "sanitises PS names into valid PDF name tokens" do
      data = sfnt_bytes("\x00\x01\x00\x00", "Weird Font(Name)")
      doc.fonts.add(StringIO.new(data))
      expect(font_names(doc).first).not_to match(/[ ()<>\[\]{}\/%]/)
    end

    it "produces a BaseFont with subset tag plus PS name" do
      Tempfile.create(["ps-name-base", ".ttf"]) do |f|
        f.binmode
        f.write(sfnt_bytes("\x00\x01\x00\x00", "RiboseLogoType-Alternate"))
        f.close

        resource = doc.fonts.add(f.path)
        font_ref = doc.pages.pages_root.value[:Resources][:Font][resource]
        font_dict = doc.object(font_ref)
        base_font = font_dict.value[:BaseFont].to_s
        expect(base_font).to match(/\A[A-Z]{6}\+RiboseLogoType-Alternate\z/)
      end
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
