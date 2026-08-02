# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Writer do
  let(:doc) { Pdfrb::Document.new }
  let(:io) { StringIO.new }

  it "writes a valid PDF header" do
    described_class.write(doc, io)
    io.rewind
    header = io.gets
    expect(header).to start_with("%PDF-1.4")
    binary_marker = io.gets
    expect(binary_marker).to start_with("%\xE2\xE3\xCF\xD3".b)
  end

  it "writes a trailer with %%EOF" do
    described_class.write(doc, io)
    io.rewind
    body = io.read
    expect(body).to end_with("%%EOF\n")
    expect(body).to include("startxref")
    expect(body).to include("/Root")
  end

  it "writes an xref section with the Catalog object" do
    described_class.write(doc, io)
    io.rewind
    body = io.read
    expect(body).to include("xref")
    expect(body).to include("/Type /Catalog")
    expect(body).to include("/Type /Pages")
  end
end

RSpec.describe "end-to-end Document write/read" do
  it "round-trips an empty doc through write -> read" do
    src = Pdfrb::Document.new
    out = StringIO.new
    Pdfrb::Writer.write(src, out)

    out.rewind
    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.catalog[:Type]).to eq(:Catalog)
    pages_ref = dest.catalog.value[:Pages]
    pages = dest.object(pages_ref)
    expect(pages[:Count]).to eq(0)
  end
end
