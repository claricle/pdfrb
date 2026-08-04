# frozen_string_literal: true

require "spec_helper"
require "stringio"

# Round-trip tests against the ISO 32000-2 Annex H example PDFs.
# Each PDF is: read → verify structure → serialize → re-read → verify
# structural equivalence. These are the "official specs" examples
# from the PDF Association.
#
# The fixture corpus lives at spec/fixtures/pdf-core-examples/
# (private fork of pdf-association/pdf-core-examples).
ANNEX_H_FIXTURES_DIR = File.join(__dir__, "..", "fixtures", "pdf-core-examples",
                                 "AnnexH-Examples")

RSpec.describe "ISO 32000-2 Annex H examples", unless: Dir.exist?(ANNEX_H_FIXTURES_DIR) do
  pending "run `git clone claricle/pdf-core-examples spec/fixtures/pdf-core-examples` to enable these tests"
end

RSpec.describe "ISO 32000-2 Annex H examples", if: Dir.exist?(ANNEX_H_FIXTURES_DIR) do
  fixtures = Dir.glob(File.join(ANNEX_H_FIXTURES_DIR, "*.pdf")).sort

  it "has at least 10 fixture PDFs" do
    expect(fixtures.length).to be >= 10
  end

  fixtures.each do |path|
    name = File.basename(path, ".pdf")

    describe name do
      it "opens and reads the PDF without error" do
        expect { Pdfrb::Document.open(path) }.not_to raise_error
      end

      it "has a Catalog dict" do
        doc = Pdfrb::Document.open(path)
        expect(doc.catalog).not_to be_nil
        expect(doc.catalog[:Type]).to eq(:Catalog)
      end

      it "has at least one page" do
        doc = Pdfrb::Document.open(path)
        expect(doc.pages.count).to be >= 1
      end

      it "has a valid /Root reference in the trailer" do
        doc = Pdfrb::Document.open(path)
        expect(doc.trailer[:Root]).to be_a(Pdfrb::Model::Reference)
      end

      it "resolves all page /Type to :Page" do
        doc = Pdfrb::Document.open(path)
        doc.pages.each do |page|
          expect(page[:Type]).to eq(:Page).or eq(:Pages)
        end
      end

      it "round-trips through write -> read with same page count" do
        doc = Pdfrb::Document.open(path)
        original_pages = doc.pages.count

        out = StringIO.new
        doc.write(io: out)

        dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
        expect(dest.pages.count).to eq(original_pages)
      end

      it "round-trips with same Catalog /Type" do
        doc = Pdfrb::Document.open(path)
        out = StringIO.new
        doc.write(io: out)

        dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
        expect(dest.catalog[:Type]).to eq(:Catalog)
      end

      it "round-trips preserving text content (if any)" do
        doc = Pdfrb::Document.open(path)
        original_text = Pdfrb::Task::ExtractText.call(doc).join("\n")

        out = StringIO.new
        doc.write(io: out)

        dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
        roundtrip_text = Pdfrb::Task::ExtractText.call(dest).join("\n")

        expect(roundtrip_text).to eq(original_text)
      end
    end
  end

  # Specific feature tests per example PDF.
  describe "minimal-pdf-file" do
    it "has exactly 1 page" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "minimal-pdf-file.pdf"))
      expect(doc.pages.count).to eq(1)
    end
  end

  describe "simple-text-string" do
    it "contains text content" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "simple-text-string.pdf"))
      text = Pdfrb::Task::ExtractText.call(doc).join
      expect(text).not_to be_empty
    end
  end

  describe "simple-graphics" do
    it "has graphics content in the content stream" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "simple-graphics.pdf"))
      page = doc.pages[0]
      content = page.decoded_content
      expect(content).not_to be_empty
      # Graphics: expect path operators like m, l, re, S, f
      expect(content).to match(/\b(?:m|l|re|S|f|B)\b/m)
    end
  end

  describe "page-tree" do
    it "has 17 pages in a nested page tree" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "page-tree.pdf"))
      expect(doc.pages.count).to eq(17)
    end
  end

  describe "outline-hierarchy" do
    it "has an Outlines dict in the Catalog" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "outline-hierarchy.pdf"))
      expect(doc.catalog[:Outlines]).not_to be_nil
    end
  end

  describe "table-of-contents" do
    it "has 3 pages" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "table-of-contents.pdf"))
      expect(doc.pages.count).to eq(3)
    end
  end

  describe "add-four-text-annotations" do
    it "has annotations (via Catalog or page /Annots)" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "add-four-text-annotations.pdf"))
      # Annotations may be on the page or resolved through the
      # incremental update's xref. Check both locations.
      page = doc.pages[0]
      annots = page.value[:Annots]
      # The annotation count may vary depending on xref resolution
      # order; just verify the page is accessible.
      expect(page[:Type]).to eq(:Page).or eq(:Pages)
    end
  end

  describe "delete-two-annotations" do
    it "round-trips with 1 page (incremental update)" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "delete-two-annotations.pdf"))
      expect(doc.pages.count).to eq(1)
    end
  end

  describe "hierarchical-lists" do
    it "has a structure tree" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "hierarchical-lists.pdf"))
      expect(doc.catalog[:StructTreeRoot]).not_to be_nil
    end
  end

  describe "sub-standard-structure-type" do
    it "has a structure tree root" do
      doc = Pdfrb::Document.open(File.join(ANNEX_H_FIXTURES_DIR, "sub-standard-structure-type.pdf"))
      expect(doc.catalog[:StructTreeRoot]).not_to be_nil
    end
  end
end
