# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "golden xref table (Pdfrb::Writer#write_xref)" do
  # Issue #59 regression coverage. The classical xref table used to
  # emit 21-byte entries ("%010d %05d n \r\n" — a stray space before
  # the CRLF) where s7.5.4 requires exactly 20 bytes per entry,
  # making mutool/MuPDF report "expected trailer marker" and repair
  # the file. The byte-width fix landed in d31fcf6; this pins the
  # whole section byte-for-byte, plus that every stored offset
  # actually points at its object.

  def minimal_pdf
    doc = Pdfrb::Document.new
    # Fixed-length producer keeps object sizes (and therefore the
    # golden offsets below) stable across gem version bumps.
    doc.metadata.producer = "golden"
    doc.pages.add

    io = StringIO.new
    doc.write(io: io)
    io.string
  end

  it "emits the exact byte sequence for the xref section" do
    pdf = minimal_pdf
    xref_pos = pdf.index("xref\n")
    section = pdf[xref_pos...pdf.index("trailer")]

    entries = [
      "0000000000 65535 f", # object 0: the head free entry
      "0000000015 00000 n",
      "0000000072 00000 n",
      "0000000121 00000 n",
      "0000000161 00000 n",
      "0000000210 00000 n",
    ]
    expected = +"xref\n0 6\n"
    expected << entries.map { |e| "#{e}\r\n" }.join

    expect(section).to eq(expected)
  end

  it "keeps every entry exactly 20 bytes including the CRLF" do
    pdf = minimal_pdf
    section = pdf[pdf.index("xref\n")...pdf.index("trailer")]
    body = section.lines[2..].join

    body.each_line do |line|
      expect(line.bytesize).to eq(20)
      expect(line).to match(/\A\d{10} \d{5} [fn]\r\n\z/)
    end
  end

  it "stores offsets that point at the object headers they claim" do
    pdf = minimal_pdf
    section = pdf[pdf.index("xref\n")...pdf.index("trailer")]
    body_lines = section.lines[2..]

    body_lines.each_with_index do |line, idx|
      offset = line[0, 10].to_i
      # Entry idx addresses object idx (entry 0 is object 0, the free
      # head, whose offset field is 0 by convention).
      next if offset.zero?

      expect(pdf[offset, 12]).to start_with("#{idx} 0 obj")
    end
  end

  it "writes startxref pointing at the xref keyword" do
    pdf = minimal_pdf
    xref_pos = pdf.index("xref\n")

    expect(pdf).to match(/startxref\s+#{xref_pos}\n%%EOF\n\z/)
  end
end
