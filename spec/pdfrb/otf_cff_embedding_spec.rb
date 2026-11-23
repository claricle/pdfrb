# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "OTF (CFF) font embedding" do
  # Issue #62 regression coverage. OTF fonts with CFF outlines (OTTO
  # magic) used to be embedded as /Subtype /TrueType via /FontFile2;
  # s9.9 requires /Subtype /Type1 with /FontFile3 (the OpenType/CFF
  # program), which is what InDesign emits for the same input. The
  # fix landed in d31fcf6; the existing specs covered the magic-byte
  # classification with a stub string and left the end-to-end path
  # to a spec that skips unless a system OTF exists — i.e. it never
  # ran on CI. These specs synthesise a well-formed minimal OTF
  # (real sfnt directory + CFF table + cmap + name table) so the
  # classification, embedding and write-time CFF subsetting are all
  # pinned deterministically on every machine.

  let(:charstrings) do
    [
      "\x8b\x0e".b,                 # gid 0 (.notdef)
      "\xf7\x00\x8b\x0e".b,         # gid 1
      "\xf8\x56\x8b\x0e".b,         # gid 2
      "\xf8\x57\xf8\x58\x8b\x0e".b, # gid 3
    ]
  end

  def serialize_index(items)
    return [0].pack("n") if items.empty?

    offsets = [1]
    items.each { |i| offsets << (offsets.last + i.bytesize) }
    off_size = offsets.last < 0x100 ? 1 : 2
    buf = +"".b
    buf << [items.size].pack("n") << off_size.chr
    offsets.each { |o| buf << [o].pack(off_size == 1 ? "C" : "n") }
    items.each { |i| buf << i.b }
    buf
  end

  def private_size
    2 # Private DICT: subrs delta operand + operator
  end

  def build_top_dict(charset_off, cs_off, priv_off)
    buf = +"".b
    buf << [28, 391].pack("Cn") << 0.chr # version SID
    buf << [28, 392].pack("Cn") << 2.chr # FullName SID
    buf << [29, charset_off].pack("CN") << 15.chr
    buf << [29, cs_off].pack("CN") << 17.chr
    buf << [29, private_size].pack("CN") << [29, priv_off].pack("CN") << 18.chr
    buf
  end

  def cff_table
    header = [1, 0, 4, 4].pack("C4")
    name_index = serialize_index(["TestFont".b])
    string_index = serialize_index(["1.000".b])
    gsubr = serialize_index([])
    top_index = serialize_index([build_top_dict(0, 0, 0)])
    tail_base = header.bytesize + name_index.bytesize + top_index.bytesize +
      string_index.bytesize + gsubr.bytesize

    charset = (+"\x00".b) + [11, 12, 13].pack("n3")
    cs_index = serialize_index(charstrings)
    private_dict = +"\x8D\x13".b
    local_subrs = serialize_index(["\x8b\x0e".b, "\x8b\x0f".b])

    cs_off = tail_base
    charset_off = cs_off + cs_index.bytesize
    priv_off = charset_off + charset.bytesize
    top_index = serialize_index([build_top_dict(charset_off, cs_off, priv_off)])

    header + name_index + top_index + string_index + gsubr + cs_index +
      charset + private_dict + local_subrs
  end

  def cmap_table
    # Format 0 byte map mapping "H" (0x48) -> gid 1. Encoding record:
    # platform 3, encoding 1, u32 subtable offset.
    map = Array.new(256, 0)
    map[0x48] = 1
    [0, 1].pack("n2") + [3, 1].pack("n2") + [12].pack("N") +
      [0, 262, 0].pack("n3") + map.pack("C256")
  end

  def name_table
    str = "TestFont-Regular".encode(Encoding::UTF_16BE).b
    [0, 1, 6 + 12].pack("n3") +
      [3, 1, 0x409, 6, str.bytesize, 0].pack("n6") + str
  end

  def otf_bytes
    Pdfrb::Font::Sfnt.rebuild(
      "OTTO".b,
      [["CFF ", cff_table], ["cmap", cmap_table], ["name", name_table]]
    )
  end

  def font_dict_for(doc, resource)
    ref = doc.pages.pages_root.value[:Resources][:Font][resource]
    doc.object(ref)
  end

  def descriptor_for(doc, font_dict)
    doc.object(font_dict.value[:FontDescriptor])
  end

  it "embeds an unused OTF as Type1 with a full FontFile3/OpenType stream" do
    doc = Pdfrb::Document.new
    doc.pages.add
    resource = doc.fonts.add(StringIO.new(otf_bytes))

    font_dict = font_dict_for(doc, resource)
    expect(font_dict.value[:Subtype]).to eq(:Type1)

    descriptor = descriptor_for(doc, font_dict)
    expect(descriptor.value.key?(:FontFile3)).to be(true)
    expect(descriptor.value.key?(:FontFile2)).to be(false)

    stream = doc.object(descriptor.value[:FontFile3])
    expect(stream.value[:Subtype]).to eq(:OpenType)
    expect(stream.value[:Length1]).to eq(otf_bytes.bytesize)
    expect(stream.stream).to eq(otf_bytes) # unused: full program kept
  end

  it "subsets the FontFile3 CFF program at write time" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add(StringIO.new(otf_bytes))
    doc.pages.add.canvas.text("H", at: [72, 720], font: font, size: 24)

    io = StringIO.new
    doc.write(io: io)

    written = doc.object(descriptor_for(doc, font_dict_for(doc, font)).value[:FontFile3])
    subset = written.stream

    expect(subset.bytesize).to be < otf_bytes.bytesize
    version, = Pdfrb::Font::Sfnt.parse_directory(subset)
    expect(version).to eq("OTTO".b)
    cff = Pdfrb::Font::CFF::File.new(Pdfrb::Font::Sfnt.table_bytes(subset, "CFF "))
    expect(cff.num_glyphs).to eq(2) # .notdef + the one used glyph
    expect(written.value[:Subtype]).to eq(:OpenType)
    expect(written.value[:Length]).to eq(subset.bytesize)
  end

  it "writes no FontFile2 anywhere for a CFF font" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add(StringIO.new(otf_bytes))
    doc.pages.add.canvas.text("H", at: [72, 720], font: font, size: 24)

    io = StringIO.new
    doc.write(io: io)
    expect(io.string).not_to include("FontFile2")
  end

  it "round-trips: the written OTF parses back as a Type1 font" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add(StringIO.new(otf_bytes))
    doc.pages.add.canvas.text("H", at: [72, 720], font: font, size: 24)

    io = StringIO.new
    doc.write(io: io)
    back = Pdfrb.parse(io.string)

    resources = back.pages.first.resources
    resources = resources.value if resources.respond_to?(:value)
    fonts_map = resources[:Font]
    fonts_map = back.object(fonts_map) if fonts_map.is_a?(Pdfrb::Model::Reference)
    fonts_map = fonts_map.value if fonts_map.respond_to?(:value)
    font_dict = back.object(fonts_map.values.first)

    expect(font_dict.value[:Subtype]).to eq(:Type1)
    expect(font_dict.value[:BaseFont].to_s).to match(/\A[A-Z]{6}\+TestFont-Regular\z/)
    desc = back.object(font_dict.value[:FontDescriptor])
    stream = back.object(desc.value[:FontFile3])
    expect(stream.value[:Subtype]).to eq(:OpenType)
  end

  it "still embeds true TrueType fonts via FontFile2" do
    doc = Pdfrb::Document.new
    doc.pages.add
    ttf = Pdfrb::Font::Sfnt.rebuild(
      "\x00\x01\x00\x00".b, [["name", name_table]]
    )
    resource = doc.fonts.add(StringIO.new(ttf))

    font_dict = font_dict_for(doc, resource)
    expect(font_dict.value[:Subtype]).to eq(:TrueType)
    descriptor = descriptor_for(doc, font_dict)
    expect(descriptor.value.key?(:FontFile2)).to be(true)
    expect(descriptor.value.key?(:FontFile3)).to be(false)
  end
end
