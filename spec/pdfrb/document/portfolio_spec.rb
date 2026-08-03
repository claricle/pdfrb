# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Portfolio do
  let(:doc) { Pdfrb::Document.new }

  it "starts with default schema fields" do
    portfolio = described_class.new(doc)
    expect(portfolio.schema_fields.map(&:name)).to include("Name", "Description", "Size")
  end

  it "adds custom schema fields" do
    portfolio = described_class.new(doc)
    portfolio.add_field("Author", type: :text, subtype: :Author)
    expect(portfolio.schema_fields.last.name).to eq("Author")
  end

  it "adds portfolio items" do
    portfolio = described_class.new(doc)
    portfolio.add_item("report.pdf", "PDF content",
                       mime_type: :"application#2Fpdf", description: "Annual report")
    expect(portfolio.items.length).to eq(1)
    expect(portfolio.items.first.name).to eq("report.pdf")
  end

  it "writes /Collection on Catalog when committed" do
    portfolio = doc.portfolio
    portfolio.add_item("test.pdf", "PDF content")
    portfolio.commit!

    collection = doc.catalog.value[:Collection]
    expect(collection).not_to be_nil
    expect(collection[:Type]).to eq(:Collection)
  end

  it "creates /Filespec for each item" do
    portfolio = doc.portfolio
    portfolio.add_item("a.pdf", "AAA")
    portfolio.add_item("b.pdf", "BBB")
    portfolio.commit!

    collection = doc.catalog.value[:Collection]
    expect(collection[:Items].length).to eq(2)
  end

  it "round-trips through serialization" do
    portfolio = doc.portfolio
    portfolio.add_item("data.bin", "\x00\x01\x02", mime_type: :"application#2Foctet#2Dstream")
    portfolio.commit!

    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    collection = reparsed.catalog.value[:Collection]
    expect(collection).not_to be_nil
    expect(collection[:Items].length).to eq(1)
  end

  it "sets /AFRelationship to Unspecified on each item" do
    portfolio = doc.portfolio
    portfolio.add_item("a.pdf", "AAA")
    portfolio.commit!

    collection = doc.catalog.value[:Collection]
    items_ref = collection[:Items].first
    items_obj = doc.object(items_ref)
    expect(items_obj.value[:AFRelationship]).to eq(:Unspecified)
  end
end
