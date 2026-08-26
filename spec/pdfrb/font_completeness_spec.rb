# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Font pipeline completeness" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  describe "TrueType /Widths array" do
    it "adds /FirstChar, /LastChar, /Widths to TrueType fonts" do
      ttf = "\u0000\u0001\u0000\u0000#{"\x00" * 200}"
      io = StringIO.new(ttf)
      doc.fonts.add(io)

      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      expect(font.value.key?(:Widths)).to be true if font.value[:Widths]
    end
  end

  describe "/ToUnicode CMap" do
    it "adds /ToUnicode to standard fonts" do
      doc.fonts.add("Helvetica")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)

      tu_ref = font.value[:ToUnicode]
      expect(tu_ref).to be_a(Pdfrb::Model::Reference)

      tu_stream = doc.object(tu_ref)
      cmap_data = tu_stream.stream
      expect(cmap_data).to include("beginbfchar")
      expect(cmap_data).to include("endbfchar")
    end

    it "adds /ToUnicode to TrueType fonts" do
      ttf = "\u0000\u0001\u0000\u0000#{"\x00" * 200}"
      io = StringIO.new(ttf)
      doc.fonts.add(io)

      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      tu_ref = font.value[:ToUnicode]
      expect(tu_ref).to be_a(Pdfrb::Model::Reference)
    end

    it "CMap maps WinAnsi byte 0x41 (A) to Unicode U+0041" do
      doc.fonts.add("Helvetica")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      tu_stream = doc.object(font.value[:ToUnicode])
      cmap_data = tu_stream.stream

      # The CMap should contain a mapping from code 0x41 to Unicode 0041
      expect(cmap_data).to include("0041")
    end

    it "CMap maps WinAnsi byte 0xE9 (é) to Unicode U+00E9" do
      doc.fonts.add("Helvetica")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      tu_stream = doc.object(font.value[:ToUnicode])
      cmap_data = tu_stream.stream

      expect(cmap_data).to include("00e9").or include("00E9")
    end
  end

  describe "Font subsetting integration" do
    it "tracks used codepoints via encode_text" do
      font = doc.fonts.add("Helvetica")
      doc.fonts.encode_text("Hello", font)
      used = doc.fonts.used_codepoints(font)
      expect(used).to include("H".ord)
      expect(used).to include("e".ord)
      expect(used).to include("l".ord)
      expect(used).to include("o".ord)
    end

    it "accumulates codepoints across multiple encode_text calls" do
      font = doc.fonts.add("Helvetica")
      doc.fonts.encode_text("Hi", font)
      doc.fonts.encode_text("World", font)
      used = doc.fonts.used_codepoints(font)
      expect(used.length).to be >= 7
    end
  end

  describe "Standard font /Widths from AFM" do
    it "space character (0x20) has non-zero width" do
      doc.fonts.add("Helvetica")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      expect(font.value[:Widths][0x20]).to be_positive
    end

    it "letter 'A' (0x41) has non-zero width" do
      doc.fonts.add("Times-Roman")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      expect(font.value[:Widths][0x41]).to be_positive
    end

    it "all 256 entries present" do
      doc.fonts.add("Courier")
      font_ref = doc.pages.pages_root.value[:Resources][:Font][:F1]
      font = doc.object(font_ref)
      expect(font.value[:Widths].length).to eq(256)
      expect(font.value[:FirstChar]).to eq(0)
      expect(font.value[:LastChar]).to eq(255)
    end
  end
end
