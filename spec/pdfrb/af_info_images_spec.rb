# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::AssociatedFiles do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "adds associated file to catalog" do
    fs = doc.add({ Type: :Filespec, F: "data.xml" },
                 type: Pdfrb::Model::Cos::Dictionary)
    ref = Pdfrb::Model::Reference.new(fs.oid, fs.gen)
    doc.associated_files.add_to_catalog(ref, relationship: :Source)

    af = doc.catalog.value[:AF]
    expect(af).to include(ref)
    expect(fs.value[:AFRelationship]).to eq(:Source)
  end

  it "adds associated file to a specific page" do
    page = doc.pages.first
    fs = doc.add({ Type: :Filespec, F: "page_data.xml" },
                 type: Pdfrb::Model::Cos::Dictionary)
    ref = Pdfrb::Model::Reference.new(fs.oid, fs.gen)
    doc.associated_files.add_to_page(page, ref, relationship: :Data)

    expect(page.value[:AF]).to include(ref)
  end

  it "rejects invalid relationship type" do
    fs = doc.add({ Type: :Filespec, F: "x" },
                 type: Pdfrb::Model::Cos::Dictionary)
    ref = Pdfrb::Model::Reference.new(fs.oid, fs.gen)
    expect do
      doc.associated_files.add_to_catalog(ref, relationship: :BadType)
    end.to raise_error(ArgumentError)
  end

  it "embeds a file from raw bytes and associates it" do
    ref = doc.associated_files.embed(filename: "report.csv",
                                     data: "a,b,c\n1,2,3",
                                     relationship: :Data)
    expect(ref).to be_a(Pdfrb::Model::Reference)
    af = doc.catalog.value[:AF]
    expect(af).to include(ref)
  end

  it "lists catalog-level AF files" do
    doc.associated_files.embed(filename: "a.txt", data: "AAA")
    doc.associated_files.embed(filename: "b.txt", data: "BBB")
    expect(doc.associated_files.catalog_files.length).to eq(2)
  end

  it "round-trips through serialization" do
    doc.associated_files.embed(filename: "doc.xml", data: "<root/>",
                               relationship: :Source)
    io = StringIO.new
    doc.write(io: io)
    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    af = reparsed.catalog.value[:AF]
    expect(af).not_to be_nil
  end
end

RSpec.describe Pdfrb::Document::Info do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "sets and gets Title" do
    doc.info.title = "My Document"
    expect(doc.info.title).to eq("My Document")
  end

  it "sets Author" do
    doc.info.author = "Jane Doe"
    expect(doc.info.author).to eq("Jane Doe")
  end

  it "sets Producer" do
    doc.info.producer = "pdfrb"
    expect(doc.info.producer).to eq("pdfrb")
  end

  it "syncs to XMP packet" do
    doc.info.title = "XMP Test"
    doc.info.author = "Tester"
    xmp = doc.xmp.to_xmp
    expect(xmp).to include("XMP Test")
    expect(xmp).to include("Tester")
  end

  it "sets CreationDate from Time" do
    doc.info.creation_date = Time.utc(2026, 1, 15, 10, 30, 0)
    expect(doc.info.creation_date).to include("D:20260115103000")
  end

  it "sets Trapped" do
    doc.info.trapped = :False
    expect(doc.info.trapped).to eq(:False)
  end

  it "round-trips through serialization" do
    doc.info.title = "Round Trip"
    doc.info.author = "Author"
    io = StringIO.new
    doc.write(io: io)
    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reparsed.info.title).to eq("Round Trip")
  end

  it "creates /Info on trailer" do
    doc.info.title = "Test"
    expect(doc.trailer[:Info]).to be_a(Pdfrb::Model::Reference)
  end
end

RSpec.describe Pdfrb::Conformance::PdfA do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "A-1 flags LZWDecode" do
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    stream = doc.add({ Filter: :LZWDecode, Length: 3 },
                     type: Pdfrb::Model::Cos::Stream)
    stream.stream = "\x00\x01\x02"

    result = described_class.validate(doc, level: :a1b)
    v = result.violations.find { |x| x.rule_id == "a1-4" }
    expect(v).not_to be_nil
  end

  it "A-2 flags embedded files" do
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    stream = doc.add({ Type: :EmbeddedFile, Length: 3 },
                     type: Pdfrb::Model::Cos::Stream)
    stream.stream = "ABC"

    result = described_class.validate(doc, level: :a2b)
    v = result.violations.find { |x| x.rule_id == "a2-2" }
    expect(v).not_to be_nil
  end

  it "A-3 allows embedded files" do
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    stream = doc.add({ Type: :EmbeddedFile, Length: 3 },
                     type: Pdfrb::Model::Cos::Stream)
    stream.stream = "ABC"
    doc.add({ Type: :Filespec, F: "data.bin",
              AFRelationship: :Unspecified },
            type: Pdfrb::Model::Cos::Dictionary)

    result = described_class.validate(doc, level: :a3b)
    v = result.violations.find { |x| x.rule_id == "a2-2" }
    expect(v).to be_nil
  end
end

RSpec.describe Pdfrb::Content::Canvas do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "emits q/cm/Do/Q for draw_image" do
    canvas.draw_image(:Im1, at: [72, 72], width: 200, height: 100)
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("q")
    expect(data).to include("Do")
    expect(data).to include("Q")
    expect(data).to include("/Im1")
  end

  it "applies the correct transform matrix" do
    canvas.draw_image(:Im1, at: [100, 200], width: 50, height: 60)
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("100")
    expect(data).to include("200")
  end
end
