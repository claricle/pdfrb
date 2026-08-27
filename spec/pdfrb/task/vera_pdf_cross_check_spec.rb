# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Task::VeraPdfCrossCheck do
  let(:sample_xml) do
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <report>
        <validationReport isCompliant="false" profileName="PDF/A-2b validation profile">
          <details passedRules="10" failedRules="1" passedChecks="50" failedChecks="1">
            <rule specification="ISO 19005-2:2011" clause="6.1.3" testNumber="1" status="failed">
              <description>Missing ID</description>
              <check status="failed">
                <context>root/document[0]</context>
                <errorMessage>Missing or empty ID in the document trailer</errorMessage>
              </check>
            </rule>
          </details>
        </validationReport>
      </report>
    XML
  end

  describe ".parse_report" do
    it "extracts counts, profile, and failure detail" do
      result = described_class.parse_report(sample_xml)
      expect(result).not_to be_compliant
      expect(result.profile).to include("PDF/A-2b")
      expect(result.passed_rules).to eq(10)
      expect(result.failed_rules).to eq(1)
      expect(result.failures.size).to eq(1)

      failure = result.failures.first
      expect(failure.clause).to include("6.1.3")
      expect(failure.description).to eq("Missing ID")
      expect(failure.message).to include("trailer")
      expect(failure.context).to eq("root/document[0]")
    end
  end

  describe ".available?" do
    it "returns a boolean without raising" do
      expect(described_class.available?(binary: "/nonexistent/verapdf")).to be false
    end
  end

  describe "PDF/A cross-check (integration)", :aggregate_failures do
    let(:font_path) do
      [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      ].find { |p| File.file?(p) }
    end

    it "produces a veraPDF-compliant PDF/A-2b document" do
      skip "verapdf not installed" unless described_class.available?
      skip "no system TTF available" unless font_path

      doc = Pdfrb::Document.new
      doc.enable_pdf_a!(part: 2, conformance: "B")
      font = doc.fonts.add(font_path)
      page = doc.pages.add
      page.canvas.text("veraPDF cross-check", at: [72, 720], font: font, size: 24)

      io = StringIO.new
      doc.write(io: io)

      expect(io.string.bytesize).to be < 5_000_000 # font actually subsetted

      result = described_class.call(io.string, flavour: :a2b)
      expect(result.failures).to eq([])
      expect(result).to be_compliant

      # The subset font must still serve the text.
      reopened = Pdfrb.parse(io.string)
      text = Pdfrb::Task::ExtractText.call_single_page(reopened.pages.first)
      expect(text).to eq("veraPDF cross-check")
    end
  end
end

RSpec.describe "PDF/A generation" do
  it "installs the OutputIntent, XMP identification, and title" do
    doc = described_class.new
    doc.enable_pdf_a!(part: 2, conformance: "B")

    expect(doc.version).to eq("1.7")
    expect(doc.pdfa_part).to eq(2)
    expect(doc.pdfa_conformance).to eq("B")
    expect(doc.catalog.value[:OutputIntents]).not_to be_nil
    expect(doc.xmp.pdfa_part).to eq(2)

    io = StringIO.new
    doc.write(io: io)
    bytes = io.string
    expect(bytes).to include("/GTS_PDFA1")
    expect(bytes).to include("pdfaid:part")
    expect(bytes).to include("/ID [")
  end

  it "uses PDF 2.0 for part 4" do
    doc = described_class.new
    doc.enable_pdf_a!(part: 4, conformance: "B")
    expect(doc.version).to eq("2.0")
  end
end
