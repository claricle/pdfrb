# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Importer do
  let(:source) do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    page = doc.pages.add
    page.canvas.text("Hello", at: [72, 720], font: font, size: 24)
    doc
  end
  let(:target) { Pdfrb::Document.new }

  it "imports a page from source into target" do
    source_page = source.pages[0]
    importer = described_class.new(target)
    imported_value = importer.import(source_page.value, source)

    new_page = target.add(imported_value, type: Pdfrb::Model::Type::Page)
    expect(new_page[:Type]).to eq(:Page)
    expect(new_page.value[:Contents]).to be_a(Pdfrb::Model::Reference)
  end

  it "is idempotent for repeated references to the same oid" do
    source_page = source.pages[0]
    importer = described_class.new(target)

    imported1 = importer.import(source_page.value, source)
    imported2 = importer.import(source_page.value, source)

    # Same /Contents reference both times — single import.
    expect(imported1[:Contents].oid).to eq(imported2[:Contents].oid)
  end

  it "handles cycles without infinite recursion" do
    # Build a cycle: page parent points to Pages, Pages kids include page.
    importer = described_class.new(target)
    expect {
      importer.import(source.pages[0].value, source)
    }.not_to raise_error
  end
end

RSpec.describe Pdfrb::Task::ExtractText do
  it "extracts text from a single-page document" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hello, World!", at: [72, 720], font: font, size: 24)

    texts = described_class.call(doc)
    expect(texts.length).to eq(1)
    expect(texts.first).to include("Hello, World!")
  end

  it "extracts from TJ arrays" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    page = doc.pages.add
    page.canvas.emit_op(Pdfrb::Content::Operator::BeginText)
    page.canvas.emit_op(Pdfrb::Content::Operator::SetTextMatrix, 1, 0, 0, 1, 72, 720)
    page.canvas.emit_op(Pdfrb::Content::Operator::Font, font, 24)
    page.canvas.emit_op(Pdfrb::Content::Operator::ShowTextWithSpacing,
                        ["Hel".b, -50, "lo".b])
    page.canvas.emit_op(Pdfrb::Content::Operator::EndText)

    texts = described_class.call(doc)
    expect(texts.first).to include("Hello")
  end

  it "handles empty content streams" do
    doc = Pdfrb::Document.new
    doc.pages.add
    texts = described_class.call(doc)
    expect(texts.length).to eq(1)
    expect(texts.first).to eq("")
  end

  it "yields per page when a block is given" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("A", at: [72, 720], font: font, size: 12)
    doc.pages.add.canvas.text("B", at: [72, 720], font: font, size: 12)

    seen = []
    described_class.call(doc) { |page, text| seen << [page.oid, text] }
    expect(seen.length).to eq(2)
  end
end

RSpec.describe Pdfrb::Task::ExtractImages do
  it "finds no images in a text-only doc" do
    doc = Pdfrb::Document.new
    doc.pages.add
    expect(described_class.call(doc)).to eq([])
  end

  it "yields images when present" do
    doc = Pdfrb::Document.new
    # Stub an Image XObject in the page resources.
    image = doc.add({
      Type: :XObject,
      Subtype: :Image,
      Width: 100, Height: 100,
      BitsPerComponent: 8,
      ColorSpace: :DeviceRGB,
      Filter: :DCTDecode
    }, type: Pdfrb::Model::Cos::Stream)
    image.stream = "fake-jpeg".b

    page = doc.pages.add
    page.value[:Resources] ||= {}
    page.value[:Resources][:XObject] = { Im1: Pdfrb::Model::Reference.new(image.oid, 0) }

    results = described_class.call(doc)
    expect(results.length).to eq(1)
    expect(results.first.name).to eq("Im1")
    expect(results.first.width).to eq(100)
    expect(results.first.filter).to eq(:DCTDecode)
  end
end

RSpec.describe Pdfrb::Task::Merge do
  it "merges two single-page docs into a two-page target" do
    src1 = Pdfrb::Document.new
    font = src1.fonts.add("Helvetica")
    src1.pages.add.canvas.text("Page from src1", at: [72, 720], font: font, size: 24)

    src2 = Pdfrb::Document.new
    font2 = src2.fonts.add("Courier")
    src2.pages.add.canvas.text("Page from src2", at: [72, 720], font: font2, size: 24)

    target = Pdfrb::Document.new
    described_class.call(target, src1, src2)
    expect(target.pages.count).to eq(2)
  end

  it "preserves content stream bytes after merge" do
    src = Pdfrb::Document.new
    font = src.fonts.add("Helvetica")
    src.pages.add.canvas.text("Hello", at: [50, 700], font: font, size: 12)

    target = Pdfrb::Document.new
    described_class.call(target, src)

    out = StringIO.new
    target.write(io: out)
    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.pages.count).to eq(1)
    texts = Pdfrb::Task::ExtractText.call(dest)
    expect(texts.first).to include("Hello")
  end
end
