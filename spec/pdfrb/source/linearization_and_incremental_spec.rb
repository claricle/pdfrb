# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Source::LinearizationDetection do
  it "returns false for a non-linearized PDF" do
    src = <<~PDF.b
      %PDF-1.4
      1 0 obj
      << /Type /Catalog /Pages 2 0 R >>
      endobj
    PDF
    io = StringIO.new(src)
    expect(described_class.linearized?(io)).to be(false)
  end

  it "returns true when the first object has a /Linearized key" do
    src = <<~PDF.b
      %PDF-1.4
      1 0 obj
      << /Linearized 1 /L 1024 /H [200 100] /O 2 /E 800 /N 1 /T 600 >>
      endobj
    PDF
    io = StringIO.new(src)
    expect(described_class.linearized?(io)).to be(true)
  end

  it "is resilient to garbage at the start" do
    src = "junk\n%PDF-1.4\n1 0 obj\n<< /Linearized 1 >>\nendobj\n".b
    io = StringIO.new(src)
    expect(described_class.linearized?(io)).to be(true)
  end
end

RSpec.describe Pdfrb::Writer, "#write_incremental" do
  let(:original_bytes) do
    src = Pdfrb::Document.new
    src.metadata.title = "Original"
    font = src.fonts.add("Helvetica")
    src.pages.add.canvas.text("Hello", at: [72, 720], font: font, size: 24)
    out = StringIO.new
    src.write(io: out)
    out.string
  end

  it "appends a new revision preserving the original bytes" do
    # Open, modify a field, save incrementally.
    doc = Pdfrb::Document.new(io: StringIO.new(original_bytes.b))
    doc.metadata.title = "Updated"

    out = StringIO.new
    described_class.write_incremental(doc, out)
    result = out.string.b

    # The result must start with the original bytes verbatim.
    expect(result).to start_with(original_bytes.b)
    # ... and end with %%EOF after the appended revision.
    expect(result).to end_with("%%EOF\n")
    # Multiple startxref markers => multiple revisions present.
    expect(result.scan(/startxref/).length).to be >= 2
  end

  it "raises when the document has no source IO" do
    src = Pdfrb::Document.new
    expect {
      described_class.write_incremental(src, StringIO.new)
    }.to raise_error(Pdfrb::Error)
  end
end
