# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "FOP-generated PDF reading" do
  let(:fop_pdf) { File.expand_path("../fixtures/pdfs/oiml-r138-e07.pdf", __dir__) }

  before do
    skip "FOP PDF fixture not present" unless File.exist?(fop_pdf)
  end

  it "opens successfully" do
    expect { Pdfrb::Document.open(fop_pdf) }.not_to raise_error
  end

  it "resolves the Catalog dict" do
    doc = Pdfrb::Document.open(fop_pdf)
    expect(doc.catalog).to be_a(Pdfrb::Model::Type::Catalog)
  end

  it "resolves the Pages root to a PageTreeNode" do
    doc = Pdfrb::Document.open(fop_pdf)
    pages = doc.object(doc.catalog[:Pages])
    expect(pages).to be_a(Pdfrb::Model::Type::PageTreeNode)
  end

  it "computes the page count correctly" do
    doc = Pdfrb::Document.open(fop_pdf)
    expect(doc.pages.count).to be > 0
  end

  it "resolves each page to a Page object" do
    doc = Pdfrb::Document.open(fop_pdf)
    page = doc.pages[0]
    expect(page).to be_a(Pdfrb::Model::Type::Page)
  end

  it "round-trips through write+read without losing pages" do
    doc = Pdfrb::Document.open(fop_pdf)
    original_count = doc.pages.count
    out = StringIO.new
    doc.write(io: out)
    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    expect(reloaded.pages.count).to eq(original_count)
  end
end

RSpec.describe "Stream predictor handling" do
  it "applies PNG predictor for FlateDecode streams with DecodeParms" do
    # Create a stream that needs the predictor: encode some data
    # using PNG Up filter, then zlib, then decode.
    require "zlib"
    raw = "Hello, World! " * 10
    # Simulate a predictor-encoded stream: row = [filter_byte, *data]
    rows = raw.bytes.each_slice(10).map { |chunk| [0, *chunk] } # filter=0 (None)
    encoded = rows.map { |row| row.pack("C*") }.join
    compressed = Zlib::Deflate.deflate(encoded)

    doc = Pdfrb::Document.new
    stream = doc.add({ Length: compressed.bytesize,
                       Filter: :FlateDecode,
                       DecodeParms: { Predictor: 12, Columns: 10 } },
                     type: Pdfrb::Model::Cos::Stream)
    stream.stream = compressed
    decoded = stream.decoded_stream
    expect(decoded).to start_with("Hello, World!")
  end

  it "handles DecodeParms as Hash (not Array)" do
    doc = Pdfrb::Document.new
    stream = doc.add({ Length: 5,
                       Filter: :FlateDecode,
                       DecodeParms: { Predictor: 1 } },
                     type: Pdfrb::Model::Cos::Stream)
    # Predictor 1 = no predictor; just zlib.
    require "zlib"
    raw = "Hello"
    stream.stream = Zlib::Deflate.deflate(raw)
    expect(stream.decoded_stream).to eq("Hello")
  end
end
