# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"

RSpec.describe "font subset prefix (Pdfrb::Document::Fonts)" do
  # Issue #61 regression coverage. Embedded fonts used to be named
  # "FileFont-<basename>"; s9.6.4 requires a subset tag of exactly six
  # uppercase ASCII letters followed by "+" before the PostScript name
  # (e.g. "OZNMOQ+MinionPro-Regular"), and non-subsetted fonts keep the
  # bare PostScript name. The fix landed in d31fcf6; these specs pin it
  # using real (synthesised but well-formed) sfnt bytes rather than a
  # stub string, so the whole name-lookup path is exercised.

  def name_table(ps_name)
    str = ps_name.encode(Encoding::UTF_16BE).b
    [0, 1, 6 + 12].pack("n3") +
      [3, 1, 0x409, 6, str.bytesize, 0].pack("n6") + str
  end

  def ttf_bytes(ps_name)
    Pdfrb::Font::Sfnt.rebuild(
      "\x00\x01\x00\x00".b, [["name", name_table(ps_name)]]
    )
  end

  def font_dict_for(doc, resource)
    ref = doc.pages.pages_root.value[:Resources][:Font][resource]
    doc.object(ref)
  end

  it "prefixes the PostScript name with a 6-letter tag for path input" do
    doc = Pdfrb::Document.new
    doc.pages.add
    Tempfile.create(["subset-prefix", ".ttf"]) do |f|
      f.binmode
      f.write(ttf_bytes("TestFont-Regular"))
      f.close

      resource = doc.fonts.add(f.path)
      base_font = font_dict_for(doc, resource).value[:BaseFont].to_s

      expect(base_font).to match(/\A[A-Z]{6}\+TestFont-Regular\z/)
      expect(base_font).not_to include("FileFont")
    end
  end

  it "prefixes the PostScript name with a 6-letter tag for IO input" do
    doc = Pdfrb::Document.new
    doc.pages.add
    resource = doc.fonts.add(StringIO.new(ttf_bytes("TestFont-Regular")))
    base_font = font_dict_for(doc, resource).value[:BaseFont].to_s

    expect(base_font).to match(/\A[A-Z]{6}\+TestFont-Regular\z/)
    expect(base_font).not_to include("FileFont")
  end

  it "derives the tag deterministically from the font bytes" do
    data = ttf_bytes("TestFont-Regular")
    tags = Array.new(2) do
      doc = Pdfrb::Document.new
      doc.pages.add
      resource = doc.fonts.add(StringIO.new(data))
      font_dict_for(doc, resource).value[:BaseFont].to_s
    end

    expect(tags.uniq.length).to eq(1)
    expect(tags.first).to match(/\A[A-Z]{6}\+TestFont-Regular\z/)
  end

  it "keeps the tag to exactly six uppercase letters" do
    doc = Pdfrb::Document.new
    doc.pages.add
    resource = doc.fonts.add(StringIO.new(ttf_bytes("TestFont-Regular")))
    base_font = font_dict_for(doc, resource).value[:BaseFont].to_s

    expect(base_font[0, 6]).to match(/\A[A-Z]{6}\z/)
    expect(base_font[6]).to eq("+")
  end

  it "leaves non-subsetted standard fonts at the bare name" do
    doc = Pdfrb::Document.new
    doc.pages.add
    resource = doc.fonts.add("Helvetica")
    base_font = font_dict_for(doc, resource).value[:BaseFont]

    expect(base_font).to eq(:Helvetica)
    written = StringIO.new
    doc.write(io: written)
    expect(written.string).not_to include("FileFont")
  end
end
