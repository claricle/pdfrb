# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "zlib"

RSpec.describe "Content stream compression" do
  it "compresses page content streams when writer.compress_streams is true" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    font = doc.fonts.add("Helvetica")
    page = doc.pages.add
    page.canvas.text("Hello, World! " * 20, at: [72, 720], font: font, size: 12)

    contents_ref = page.value[:Contents]
    stream = contents_ref.is_a?(Pdfrb::Model::Reference) ? doc.object(contents_ref) : contents_ref
    original_size = stream.stream.bytesize

    doc.write(io: StringIO.new)

    expect(stream.value[:Filter]).to eq(:FlateDecode)
    expect(stream.stream.bytesize).to be < original_size
  end

  it "does not compress when config is false" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => false })
    page = doc.pages.add
    page.canvas.text("Test", at: [72, 720], font: :F1, size: 12)

    doc.write(io: StringIO.new)

    contents_ref = page.value[:Contents]
    stream = contents_ref.is_a?(Pdfrb::Model::Reference) ? doc.object(contents_ref) : contents_ref
    expect(stream.value[:Filter]).to be_nil
  end

  it "compresses to valid FlateDecode that can be decompressed" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    page = doc.pages.add
    page.canvas.text("Hello World Content for Compression Test " * 3,
                     at: [72, 720], font: :F1, size: 12)

    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    reparsed.pages.each do |pg|
      contents = pg.value[:Contents]
      next unless contents

      stream = contents.is_a?(Pdfrb::Model::Reference) ? reparsed.object(contents) : contents
      next unless stream.is_a?(Pdfrb::Model::Cos::Stream)

      if stream.value[:Filter] == :FlateDecode
        decompressed = Zlib::Inflate.inflate(stream.stream)
        expect(decompressed).to include("Compression")
      end
    end
  end

  it "skips tiny streams" do
    doc = Pdfrb::Document.new(config: { "writer.compress_streams" => true })
    page = doc.pages.add

    doc.write(io: StringIO.new)

    contents_ref = page.value[:Contents]
    stream = contents_ref.is_a?(Pdfrb::Model::Reference) ? doc.object(contents_ref) : contents_ref
    expect(stream.value[:Filter]).to be_nil
  end
end

RSpec.describe "Writer auto-version detection" do
  it "sets version to 2.0 when /AF is present" do
    doc = Pdfrb::Document.new
    doc.pages.add
    fs = doc.add({ Type: :Filespec, F: "x.txt", AFRelationship: :Data },
                 type: Pdfrb::Model::Cos::Dictionary)
    doc.associated_files.add_to_catalog(
      Pdfrb::Model::Reference.new(fs.oid, fs.gen)
    )

    doc.write(io: StringIO.new)

    expect(doc.version).to eq("2.0")
  end

  it "sets version to 2.0 when /Collection is present" do
    doc = Pdfrb::Document.new
    doc.pages.add
    doc.portfolio.add_item("test.pdf", "data")
    doc.portfolio.commit!

    doc.write(io: StringIO.new)

    expect(doc.version).to eq("2.0")
  end

  it "sets version to at least 1.5 when /OCProperties is present" do
    doc = Pdfrb::Document.new
    doc.pages.add
    doc.layers.add("Layer1")
    doc.layers.sync!

    doc.write(io: StringIO.new)

    expect(doc.version.to_f).to be >= 1.5
  end

  it "sets version to at least 1.4 when /OutputIntents is present" do
    doc = Pdfrb::Document.new
    doc.pages.add
    icc_stream = doc.add({ N: 4 }, type: Pdfrb::Model::Cos::Stream)
    doc.output_intents.add(
      Pdfrb::Model::Reference.new(icc_stream.oid, icc_stream.gen),
      identifier: "FOGRA39"
    )

    doc.write(io: StringIO.new)

    expect(doc.version.to_f).to be >= 1.4
  end

  it "keeps default version when no special features present" do
    doc = Pdfrb::Document.new
    doc.pages.add

    doc.write(io: StringIO.new)

    expect(doc.version).to eq("1.4")
  end
end

RSpec.describe Pdfrb::Font::Encoding::WinAnsiEncoding do
  describe ".encode" do
    it "encodes ASCII text unchanged" do
      encoded = described_class.encode("Hello")
      expect(encoded.bytes).to eq([72, 101, 108, 108, 111])
    end

    it "encodes high-byte WinAnsi characters" do
      encoded = described_class.encode("“")
      expect(encoded.bytes).to eq([0x93])
    end

    it "encodes em-dash" do
      encoded = described_class.encode("—")
      expect(encoded.bytes).to eq([0x97])
    end

    it "encodes trademark symbol" do
      encoded = described_class.encode("™")
      expect(encoded.bytes).to eq([0x99])
    end

    it "encodes Euro sign" do
      encoded = described_class.encode("€")
      expect(encoded.bytes).to eq([0x80])
    end

    it "substitutes unknown characters with question mark" do
      encoded = described_class.encode("中")
      expect(encoded.bytes).to eq([0x3F])
    end

    it "handles mixed ASCII and high-byte" do
      encoded = described_class.encode("café")
      expect(encoded.bytes).to eq([99, 97, 102, 0xE9])
    end
  end

  describe ".encodable?" do
    it "returns true for WinAnsi-representable codepoints" do
      expect(described_class.encodable?(65)).to be true
      expect(described_class.encodable?(0x20AC)).to be true
    end

    it "returns false for non-WinAnsi codepoints" do
      expect(described_class.encodable?(0x4E2D)).to be false
    end
  end
end
