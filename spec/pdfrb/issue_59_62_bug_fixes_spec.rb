# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"

RSpec.describe "Issues #59-#62 bug fixes" do
  let(:doc) { Pdfrb::Document.new }

  describe "Issue #59 — xref entries are 20 bytes (was 21)" do
    it "writes 20-byte entries per spec s7.5.4" do
      doc.pages.add.canvas.text("x", at: [10, 10], font: :Helvetica, size: 12)
      io = StringIO.new
      doc.write(io: io)
      pdf = io.string

      # Locate the classical xref section (preceded by newline to avoid
      # matching "startxref").
      xref_idx = pdf.index(/\nxref\n/)
      expect(xref_idx).to be_positive

      section = pdf[(xref_idx + 1)..]
      header_end = section.index("\n") + 1
      entries_start = section.index("\n", header_end) + 1
      entries_text = section[entries_start..]
      # Stop at "trailer"
      trailer_idx = entries_text.index("trailer")
      entries_blob = entries_text[0...trailer_idx]
      entries = entries_blob.split("\r\n").reject(&:empty?)
      expect(entries).not_to be_empty
      entries.each do |entry|
        # Format: "nnnnnnnnnn ggggg X" — exactly 18 chars + CRLF = 20 bytes
        expect(entry).to match(/\A\d{10} \d{5} [fn]\z/)
        expect(entry.length).to eq(18)
      end
    end
  end

  describe "Issue #60 — Info dict has no spurious /Type/Metadata" do
    it "does not add /Type to the /Info dict" do
      doc.metadata.title = "Test"
      io = StringIO.new
      doc.write(io: io)
      pdf = io.string

      # Locate the /Info dict (it has /Title "Test")
      info_idx = pdf.index(%(/Title (Test)))
      expect(info_idx).to be_positive

      # Scan back to the start of the dict
      dict_start = pdf.rindex("<<", info_idx)
      dict_end = pdf.index(">>", info_idx)
      dict_text = pdf[dict_start..dict_end]
      expect(dict_text).not_to include("/Type")
    end
  end

  describe "Issue #61 — Font subset prefix is 6-char tag (was 'FileFont-')" do
    it "uses ABCDEF+ prefix format" do
      # Create a minimal TTF-like file so add() goes through the file path
      Tempfile.create(["test", ".ttf"]) do |f|
        f.write("\u0000\u0001\u0000\u0000#{"\x00" * 100}")
        f.close

        resource = doc.fonts.add(f.path)
        font_ref = doc.pages.pages_root.value[:Resources][:Font][resource]
        font = doc.object(font_ref)

        base_font = font[:BaseFont].to_s
        expect(base_font).to match(/\A[A-Z]{6}\+.*\z/)
        expect(base_font).not_to start_with("FileFont-")
      end
    end
  end

  describe "Issue #62 — OTF (CFF) embedded as Type1 not TrueType" do
    it "classifies OTTO magic as CFF/Type1" do
      otf = "OTTO#{"\x00" * 100}"
      io = StringIO.new(otf)
      resource = doc.fonts.add(io)

      font_ref = doc.pages.pages_root.value[:Resources][:Font][resource]
      font = doc.object(font_ref)
      expect(font[:Subtype]).to eq(:Type1)

      # Font descriptor should use FontFile3 with /Subtype /OpenType,
      # not FontFile2.
      desc_ref = font[:FontDescriptor]
      desc = doc.object(desc_ref)
      expect(desc.value.key?(:FontFile3)).to be true
      expect(desc.value.key?(:FontFile2)).to be false

      font_file = doc.object(desc.value[:FontFile3])
      expect(font_file.value[:Subtype]).to eq(:OpenType)
    end

    it "still classifies true TTF magic as TrueType" do
      ttf = "\u0000\u0001\u0000\u0000#{"\x00" * 100}"
      io = StringIO.new(ttf)
      resource = doc.fonts.add(io)

      font_ref = doc.pages.pages_root.value[:Resources][:Font][resource]
      font = doc.object(font_ref)
      expect(font[:Subtype]).to eq(:TrueType)

      desc_ref = font[:FontDescriptor]
      desc = doc.object(desc_ref)
      expect(desc.value.key?(:FontFile2)).to be true
      expect(desc.value.key?(:FontFile3)).to be false
    end
  end
end
