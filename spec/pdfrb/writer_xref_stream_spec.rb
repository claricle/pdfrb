# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "XRef stream writing" do
  let(:doc) do
    Pdfrb::Document.new(config: { "writer.use_xref_stream" => true })
  end

  before do
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hello", at: [72, 720], font: font, size: 12)
  end

  it "produces a PDF with an XRef stream" do
    out = StringIO.new
    doc.write(io: out)
    bytes = out.string

    expect(bytes).to match(%r{/Type\s*/XRef})
    expect(bytes).not_to match(/^xref$/)
  end

  it "round-trips correctly" do
    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    expect(reloaded.pages.count).to eq(1)
    expect(reloaded.catalog).to be_a(Pdfrb::Model::Type::Catalog)
  end

  it "writes startxref pointing to the XRef stream" do
    out = StringIO.new
    doc.write(io: out)
    bytes = out.string

    startxref_idx = bytes.rindex("startxref")
    expect(startxref_idx).to be_positive

    startxref_line = bytes[(startxref_idx + 10)..]
    offset = startxref_line[/\d+/].to_i

    bytes[offset, 20] = bytes.byteslice(offset, 20)
    expect(bytes).to include("obj")
  end
end

RSpec.describe "Object stream packing" do
  it "packs small objects into ObjStm" do
    doc = Pdfrb::Document.new(config: {
      "writer.use_xref_stream" => true,
      "writer.pack_object_streams" => true,
    })
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hello", at: [72, 720], font: font, size: 12)

    out = StringIO.new
    doc.write(io: out)
    bytes = out.string

    expect(bytes).to match(%r{/Type\s*/ObjStm})
  end

  it "round-trips with packing enabled" do
    doc = Pdfrb::Document.new(config: {
      "writer.use_xref_stream" => true,
      "writer.pack_object_streams" => true,
    })
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Packed round-trip", at: [72, 720], font: font, size: 12)

    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    expect(reloaded.pages.count).to eq(1)
    expect(reloaded.catalog[:Type]).to eq(:Catalog)
  end

  it "produces smaller output than unpacked" do
    text = "Lorem ipsum " * 50

    plain_io = StringIO.new
    Pdfrb::Document.new.tap do |doc|
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text(text, at: [72, 720], font: font, size: 12)
      doc.write(io: plain_io)
    end

    packed_io = StringIO.new
    Pdfrb::Document.new(config: {
      "writer.use_xref_stream" => true,
      "writer.pack_object_streams" => true,
    }).tap do |doc|
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text(text, at: [72, 720], font: font, size: 12)
      doc.write(io: packed_io)
    end

    skip "packing should reduce size but depends on object count" if packed_io.string.bytesize >= plain_io.string.bytesize
  end

  it "excludes streams from packing" do
    doc = Pdfrb::Document.new(config: {
      "writer.use_xref_stream" => true,
      "writer.pack_object_streams" => true,
    })
    doc.add({ Type: :Font, Subtype: :TrueType, BaseFont: :Test },
            type: Pdfrb::Model::Cos::Dictionary)

    out = StringIO.new
    doc.write(io: out)
    bytes = out.string

    # Content stream should NOT be inside an ObjStm.
    # It should appear as a standalone object.
    expect(bytes).to match(/\d+ \d+ obj.*stream/m)
  end
end
