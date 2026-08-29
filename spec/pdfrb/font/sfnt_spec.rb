# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Font::Sfnt do
  let(:otf_path) do
    Dir.glob("/System/Library/Fonts/**/*.otf").first ||
      Dir.glob(File.expand_path("~/Library/Fonts/**/*.otf")).first
  end

  it "round-trips directory entries and table bytes" do
    skip "no system OTF available" unless otf_path

    bytes = File.binread(otf_path)
    version, entries = described_class.parse_directory(bytes)
    expect(version).to eq("OTTO".b)
    expect(entries).not_to be_empty

    head = entries.find { |e| e.tag == "head" }
    expect(head).not_to be_nil
    expect(described_class.table_bytes(bytes, "head").bytesize)
      .to eq(head.byte_length)
  end

  it "rebuilds a wrapper whose tables re-parse to identical bytes" do
    skip "no system OTF available" unless otf_path

    bytes = File.binread(otf_path)
    version, entries = described_class.parse_directory(bytes)
    tables = entries.map { |e| [e.tag, bytes.byteslice(e.offset, e.byte_length)] }
    rebuilt = described_class.rebuild(version, tables)

    _v2, entries2 = described_class.parse_directory(rebuilt)
    expect(entries2.map(&:tag)).to eq(entries.map(&:tag).sort)
    entries2.each do |e2|
      original = tables.to_h[e2.tag]
      expect(rebuilt.byteslice(e2.offset, e2.byte_length)).to eq(original)
    end
  end

  it "computes sfnt checksums over zero-padded u32s" do
    expect(described_class.checksum("\x00\x00\x00\x01")).to eq(1)
    expect(described_class.checksum("\xFF\xFF\xFF\xFF")).to eq(0xFFFFFFFF)
    expect(described_class.checksum("\x00\x00\x00\x01\x01"))
      .to eq(0x0000_0001 + 0x0100_0000)
  end
end

RSpec.describe "TrueType subsetting regression" do
  let(:ttf_path) do
    [
      "/System/Library/Fonts/Supplemental/Arial.ttf",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ].find { |p| File.file?(p) }
  end

  it "actually shrinks the font (no silent full-font fallback)" do
    skip "no system TTF available" unless ttf_path

    data = File.binread(ttf_path)
    ttf = Pdfrb::Font::TrueType::File.new(data)
    subset = Pdfrb::Font::TrueType::Subsetter.new(ttf, [72, 105]).subset

    expect(subset.bytesize).to be < data.bytesize
    re = Pdfrb::Font::TrueType::File.new(subset)
    expect(re.num_glyphs).to eq(3)
    expect(re.cmap.glyph_id_for(72)).to eq(1)
  end
end
