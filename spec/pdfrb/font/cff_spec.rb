# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Font::CFF do
  # Hand-built minimal CFF: header, Name INDEX ("TestFont"), Top DICT
  # (version/FullName SIDs, charset + CharStrings + Private offsets),
  # String INDEX, empty Global Subr INDEX, format-0 charset,
  # CharStrings INDEX of 4 glyphs, Private DICT with a Local Subr
  # INDEX.
  let(:charstrings) do
    [
      "\x8b\x0e".b,           # gid 0 (.notdef): 0 0 endchar-ish
      "\xf7\x00\x8b\x0e".b,   # gid 1: rmoveto-ish
      "\xf8\x56\x8b\x0e".b,   # gid 2
      "\xf8\x57\xf8\x58\x8b\x0e".b, # gid 3
    ]
  end

  let(:cff_bytes) do
    name_index = serialize_index(["TestFont".b])
    string_index = serialize_index(["1.000".b])

    header = [1, 0, 4, 4].pack("C4") # major minor hdrSize offSize

    # Placeholder Top DICT INDEX (offsets patched below).
    top_index = serialize_index([build_top_dict(0, 0, 0)])
    gsubr = serialize_index([])
    tail_base = header.bytesize + name_index.bytesize + top_index.bytesize +
      string_index.bytesize + gsubr.bytesize

    charset = (+"\x00".b) + [11, 12, 13].pack("n3")
    cs_index = serialize_index(charstrings)
    # operand 2 (0x8D) + operator 19 (Subrs): local subrs INDEX sits
    # 2 bytes after the Private DICT start, i.e. immediately after.
    private = +"\x8D\x13".b
    local_subrs = serialize_index(["\x8b\x0e".b, "\x8b\x0f".b])

    cs_off = tail_base
    charset_off = cs_off + cs_index.bytesize
    priv_off = charset_off + charset.bytesize

    top_index = serialize_index([build_top_dict(charset_off, cs_off, priv_off)])
    header + name_index + top_index + string_index + gsubr + cs_index +
      charset + private + local_subrs
  end

  def build_top_dict(charset_off, cs_off, priv_off)
    buf = +"".b
    buf << [28, 391].pack("Cn") << 0.chr  # version SID
    buf << [28, 392].pack("Cn") << 2.chr  # FullName SID
    buf << [29, charset_off].pack("CN") << 15.chr
    buf << [29, cs_off].pack("CN") << 17.chr
    buf << [29, private_size].pack("CN") << [29, priv_off].pack("CN") << 18.chr
    buf
  end

  def private_size
    2 # the Private DICT: operand (subrs delta) + operator
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

  describe "parsing" do
    it "reads the header and INDEXes" do
      cff = described_class::File.new(cff_bytes)
      expect(cff.num_glyphs).to eq(4)
      expect(cff.name_index.items).to eq(["TestFont".b])
      expect(cff.global_subrs.size).to eq(0)
      expect(cff.charstring(3).bytesize).to eq(6)
    end

    it "resolves the charset and private span" do
      cff = described_class::File.new(cff_bytes)
      expect(cff.charset_format).to eq(0)
      expect(cff.sid_for_gid(1)).to eq(11)
      expect(cff.gid_for_sid(13)).to eq(3)
      expect(cff.private_span).to be_a(Array)
      expect(cff.local_subrs.size).to eq(2)
    end

    it "round-trips INDEX serialization" do
      parsed, = described_class::Index.parse(cff_bytes, 4)
      expect(parsed.serialize).to eq(cff_bytes.byteslice(4, parsed.serialize.bytesize))
    end
  end

  describe "subsetting" do
    it "keeps only requested glyphs and remaps the charset" do
      cff = described_class::File.new(cff_bytes)
      subsetter = described_class::Subsetter.new(cff, [2])
      subset = subsetter.subset
      expect(subset.bytesize).to be < cff_bytes.bytesize

      re = described_class::File.new(subset)
      expect(re.num_glyphs).to eq(2)
      expect(re.charstring(1)).to eq(charstrings[2])
      expect(re.sid_for_gid(1)).to eq(12)
      expect(subsetter.glyph_map[2]).to eq(1)
    end

    it "copies subrs and private dict verbatim" do
      cff = described_class::File.new(cff_bytes)
      subset = described_class::Subsetter.new(cff, [1]).subset
      re = described_class::File.new(subset)
      expect(re.local_subrs.size).to eq(2)
      expect(re.private_span[1]).to eq(cff.private_span[1])
    end

    it "returns the original bytes when everything is kept" do
      cff = described_class::File.new(cff_bytes)
      subset = described_class::Subsetter.new(cff, (0...4).to_a).subset
      expect(subset).to eq(cff_bytes)
    end

    it "subsets range-encoded charsets by re-emitting format 0" do
      cff = described_class::File.new(cff_bytes)
      allow(cff).to receive(:charset_format).and_return(1)
      subset = described_class::Subsetter.new(cff, [2]).subset
      re = described_class::File.new(subset)
      expect(re.num_glyphs).to eq(2)
      expect(re.charset_format).to eq(0)
      expect(re.sid_for_gid(1)).to eq(12)
    end

    it "falls back to the full font for implicit charsets" do
      cff = described_class::File.new(cff_bytes)
      allow(cff).to receive(:charset_format).and_return(nil)
      subset = described_class::Subsetter.new(cff, [1]).subset
      expect(subset).to eq(cff.data)
    end
  end

  describe "with a system OTF (smoke)", :aggregate_failures do
    let(:otf_path) do
      Dir.glob("/System/Library/Fonts/**/*.otf").first ||
        Dir.glob(File.expand_path("~/Library/Fonts/**/*.otf")).first
    end

    it "parses and subsets a real CFF table" do
      skip "no system OTF available" unless otf_path

      otf = Pdfrb::Font::TrueType::File.new(File.binread(otf_path))
      cff_table = otf.table("CFF ")
      skip "font has no CFF table" unless cff_table

      cff = described_class::File.new(cff_table)
      expect(cff.num_glyphs).to be_positive

      subset = described_class::Subsetter.new(cff, [1, 2, 3]).subset
      re = described_class::File.new(subset)
      expect(re.num_glyphs).to eq(4)
      expect(re.charstring(1)).to eq(cff.charstring(1))
      expect(subset.bytesize).to be < cff_table.bytesize
    end
  end

  describe "embedding via Document#fonts (end-to-end)" do
    let(:otf_path) do
      Dir.glob("/System/Library/Fonts/**/*.otf").first ||
        Dir.glob(File.expand_path("~/Library/Fonts/**/*.otf")).first
    end

    it "embeds a subsetted FontFile3/OpenType stream" do
      skip "no system OTF available" unless otf_path
      original = File.binread(otf_path)
      skip "font has no CFF table" unless original.byteslice(0, 4) == "OTTO".b

      doc = Pdfrb::Document.new
      font = doc.fonts.add(StringIO.new(original))
      page = doc.pages.add
      page.canvas.text("Hi", at: [72, 720], font: font, size: 24)

      io = StringIO.new
      doc.write(io: io)

      doc2 = Pdfrb.parse(io.string)
      expect(doc2.pages.count).to eq(1)

      # Fonts live on the page-tree root and are inherited (s7.7.3.2).
      resources = doc2.pages.first.resources
      resources = resources.value if resources.respond_to?(:value)
      fonts_map = resources[:Font]
      fonts_map = doc2.object(fonts_map) if fonts_map.is_a?(Pdfrb::Model::Reference)
      fonts_map = fonts_map.value if fonts_map.respond_to?(:value)
      some_font = fonts_map.values.first
      some_font = doc2.object(some_font) if some_font.is_a?(Pdfrb::Model::Reference)
      desc = doc2.object(some_font.value[:FontDescriptor])
      stream = doc2.object(desc.value[:FontFile3] || desc.value[:FontFile2])

      expect(desc.value.key?(:FontFile3)).to be true
      expect(stream.value[:Subtype]).to eq(:OpenType)
      expect(stream.stream.bytesize).to be < original.bytesize
    end
  end
end
