# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Source::HeaderReader do
  it "reads a clean PDF header" do
    io = StringIO.new("%PDF-1.7\n%binary\n")
    expect(described_class.read(io)).to eq("1.7")
  end

  it "reads a 2.0 header" do
    io = StringIO.new("%PDF-2.0\n")
    expect(described_class.read(io)).to eq("2.0")
  end

  it "tolerates leading garbage" do
    io = StringIO.new("junk\n%PDF-1.4\n")
    expect(described_class.read(io)).to eq("1.4")
  end

  it "returns nil when no header is found" do
    io = StringIO.new("no pdf here")
    expect(described_class.read(io)).to be_nil
  end
end

RSpec.describe Pdfrb::Source::TrailerReader do
  it "locates the startxref offset" do
    src = "stuff\nstartxref\n1234\n%%EOF\n"
    io = StringIO.new(src.b)
    expect(described_class.startxref_offset(io)).to eq(1234)
  end

  it "uses the last startxref when multiple exist" do
    src = "startxref\n10\nstuff\nstartxref\n99\n%%EOF\n"
    io = StringIO.new(src.b)
    expect(described_class.startxref_offset(io)).to eq(99)
  end

  it "returns nil when no startxref is present" do
    io = StringIO.new("no startxref here")
    expect(described_class.startxref_offset(io)).to be_nil
  end
end

RSpec.describe Pdfrb::Source::XrefTableReader do
  it "parses a single-subsection xref" do
    src = <<~PDF
      xref
      0 3
      0000000000 65535 f \r
      0000000015 00000 n \r
      0000000100 00000 n \r
    PDF
    io = StringIO.new(src.b)
    section = described_class.read(io, 0)
    expect(section[1]).to be_in_use
    expect(section[1].offset).to eq(15)
    expect(section[2].offset).to eq(100)
    expect(section[0]).to be_free
  end
end
