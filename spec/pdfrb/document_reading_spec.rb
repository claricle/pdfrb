# frozen_string_literal: true

require "spec_helper"
require "stringio"

# A minimal hand-crafted PDF with a Catalog, an empty Pages tree,
# Info dict, and a classical xref table.
MINIMAL_PDF = <<~PDF.b
  %PDF-1.4
  1 0 obj
  << /Type /Catalog /Pages 2 0 R >>
  endobj
  2 0 obj
  << /Type /Pages /Kids [] /Count 0 >>
  endobj
  3 0 obj
  << /Type /Info /Producer (pdfrb test) >>
  endobj
  xref
  0 4
  0000000000 65535 f \r
  0000000009 00000 n \r
  0000000058 00000 n \r
  0000000115 00000 n \r
  trailer
  << /Size 4 /Root 1 0 R /Info 3 0 R >>
  startxref
  190
  %%EOF
PDF

# Fix offsets to match the actual byte positions.
MINIMAL_PDF_FIXED = begin
  bytes = MINIMAL_PDF.dup
  # Locate "1 0 obj" / "2 0 obj" / "3 0 obj" offsets.
  off1 = bytes.index("1 0 obj")
  off2 = bytes.index("2 0 obj")
  off3 = bytes.index("3 0 obj")
  startxref = bytes.index("xref")
  # Rewrite the xref entries with correct offsets. The classical xref
  # format uses zero-padded 10-digit offsets; we replace each entry
  # line with the right value.
  bytes.gsub!("0000000009 00000 n", "%010d 00000 n" % off1)
  bytes.gsub!("0000000058 00000 n", "%010d 00000 n" % off2)
  bytes.gsub!("0000000115 00000 n", "%010d 00000 n" % off3)
  bytes.gsub!("startxref\n190\n", "startxref\n#{startxref}\n")
  bytes
end

RSpec.describe "end-to-end Document reading" do
  let(:doc) { Pdfrb::Document.new(io: StringIO.new(MINIMAL_PDF_FIXED)) }

  it "parses the header version" do
    expect(doc.version).to eq("1.4")
  end

  it "loads the xref" do
    expect(doc.xref).not_to be_nil
    expect(doc.xref[1]).to be_in_use
    expect(doc.xref[2]).to be_in_use
    expect(doc.xref[3]).to be_in_use
  end

  it "resolves the Catalog" do
    catalog = doc.catalog
    expect(catalog).to be_a(Pdfrb::Model::Cos::Dictionary)
    expect(catalog[:Type]).to eq(:Catalog)
    # catalog[:Pages] auto-resolves the Reference via Document#object.
    expect(catalog.value[:Pages]).to be_a(Pdfrb::Model::Reference)
    expect(catalog[:Pages]).to be_a(Pdfrb::Model::Cos::Dictionary)
  end

  it "resolves the Pages tree" do
    pages_ref = doc.catalog[:Pages]
    pages = doc.object(pages_ref)
    expect(pages[:Type]).to eq(:Pages)
    expect(pages[:Count]).to eq(0)
  end

  it "resolves the Info dict" do
    info_ref = doc.trailer[:Info]
    info = doc.object(info_ref)
    expect(info[:Producer].force_encoding("UTF-8")).to eq("pdfrb test")
  end
end

# TODO 33: real-PDF round-trip milestone.
RSpec.describe "real-PDF round-trip (TODO 33)" do
  it "reads MINIMAL_PDF and writes a re-readable PDF with same Catalog" do
    src = StringIO.new(MINIMAL_PDF_FIXED)
    doc1 = Pdfrb::Document.new(io: src)
    catalog1_type = doc1.catalog[:Type]
    pages1_count = doc1.object(doc1.catalog.value[:Pages])[:Count]

    out = StringIO.new
    Pdfrb::Writer.write(doc1, out)

    doc2 = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(doc2.catalog[:Type]).to eq(catalog1_type)
    expect(doc2.object(doc2.catalog.value[:Pages])[:Count]).to eq(pages1_count)
  end

  it "creates an empty PDF from scratch and round-trips it" do
    src = Pdfrb::Document.new
    out = StringIO.new
    Pdfrb::Writer.write(src, out)

    doc = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(doc.catalog[:Type]).to eq(:Catalog)
    expect(doc.object(doc.catalog.value[:Pages])[:Count]).to eq(0)
  end
end
