# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Info dictionary" do
  # Issue #60 regression coverage. Document::Metadata#info_dict used to
  # set Type: :Metadata on the /Info dict; PDF 2.0 s7.9.2 defines no
  # /Type key for the document information dictionary (that /Type
  # /Metadata belongs on the XMP metadata stream, s14.3.2). PDF/A
  # validators flag the unknown key. The fix landed in d31fcf6; these
  # specs pin it from the written bytes and the parsed model.

  def written_pdf
    doc = Pdfrb::Document.new
    doc.metadata.title = "Test"
    doc.metadata.producer = "pdfrb issue-60 spec"

    io = StringIO.new
    doc.write(io: io)
    io.string
  end

  it "writes an Info dict with no /Type key" do
    pdf = written_pdf
    info_idx = pdf.index(%(/Title (Test)))
    expect(info_idx).to be_positive

    dict_start = pdf.rindex("<<", info_idx)
    dict_end = pdf.index(">>", info_idx)
    dict_text = pdf[dict_start..dict_end]
    expect(dict_text).not_to include("/Type")
    expect(dict_text).to include("/Producer (pdfrb issue-60 spec)")
  end

  it "parses back with only metadata fields on the Info dict" do
    back = Pdfrb::Document.new(io: StringIO.new(written_pdf))
    info = back.object(back.trailer[:Info])

    expect(info.value.keys).to eq(%i[Title Producer])
    expect(info[:Title]).to eq("Test")
    expect(info[:Producer]).to eq("pdfrb issue-60 spec")
  end

  it "still marks the XMP metadata stream /Type /Metadata" do
    # The removal must be limited to /Info: the XMP stream keeps its
    # own /Type /Metadata + /Subtype /XML (s14.3.2).
    doc = Pdfrb::Document.new
    doc.pages.add
    doc.info.title = "Typed stream"

    io = StringIO.new
    doc.write(io: io)
    back = Pdfrb::Document.new(io: StringIO.new(io.string))

    metadata = back.object(back.catalog.value[:Metadata])
    expect(metadata[:Type]).to eq(:Metadata)
    expect(metadata[:Subtype]).to eq(:XML)
  end
end
