# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "write-time FlateDecode compression" do
  let(:large_text) { "Hello, World! " * 200 } # ~3KB

  it "does not compress by default" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text(large_text, at: [72, 720], font: font, size: 12)
    out = StringIO.new
    doc.write(io: out)
    expect(out.string).not_to include("/Filter /FlateDecode")
  end

  it "compresses large streams when enabled" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text(large_text, at: [72, 720], font: font, size: 12)
    out = StringIO.new
    doc.write(io: out)
    expect(out.string).to include("/Filter /FlateDecode")
  end

  it "produces a smaller PDF when compression is enabled" do
    text = "Lorem ipsum dolor sit amet " * 500

    uncompressed_io = StringIO.new
    doc1 = Pdfrb::Document.new
    font1 = doc1.fonts.add("Helvetica")
    doc1.pages.add.canvas.text(text, at: [72, 720], font: font1, size: 12)
    doc1.write(io: uncompressed_io)

    compressed_io = StringIO.new
    doc2 = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    font2 = doc2.fonts.add("Helvetica")
    doc2.pages.add.canvas.text(text, at: [72, 720], font: font2, size: 12)
    doc2.write(io: compressed_io)

    expect(compressed_io.string.bytesize).to be < uncompressed_io.string.bytesize
  end

  it "round-trips correctly when compressed" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text(large_text, at: [72, 720], font: font, size: 12)
    out = StringIO.new
    doc.write(io: out)

    # Read back
    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    expect(reloaded.catalog).not_to be_nil
    pages = reloaded.object(reloaded.catalog[:Pages])
    expect(pages[:Count]).to eq(1)
  end
end
