# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Compare do
  let(:doc_a) do
    Pdfrb::Document.new.tap do |doc|
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text("Hello, World!", at: [72, 720], font: font, size: 12)
    end
  end

  let(:doc_a_copy) do
    Pdfrb::Document.new.tap do |doc|
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text("Hello, World!", at: [72, 720], font: font, size: 12)
    end
  end

  let(:doc_b) do
    Pdfrb::Document.new.tap do |doc|
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text("Goodbye, World!", at: [72, 720], font: font, size: 12)
    end
  end

  describe ".compare" do
    it "returns a Report" do
      report = described_class.compare(doc_a, doc_a_copy)
      expect(report).to be_a(Pdfrb::Compare::Report)
    end

    it "reports equivalence for identical docs" do
      report = described_class.compare(doc_a, doc_a_copy)
      expect(report.equivalent?).to be true
    end

    it "detects text differences" do
      report = described_class.compare(doc_a, doc_b)
      expect(report.equivalent?).to be false
      expect(report.per_page_text_diffs).not_to be_empty
    end

    it "reports page count delta" do
      doc_two_pages = Pdfrb::Document.new.tap do |doc|
        doc.pages.add
        doc.pages.add
      end
      doc_one_page = Pdfrb::Document.new.tap { |d| d.pages.add }

      report = described_class.compare(doc_one_page, doc_two_pages)
      expect(report.page_count_delta).to eq(1)
    end
  end

  describe ".equivalent?" do
    it "returns true for identical docs" do
      expect(described_class.equivalent?(doc_a, doc_a_copy)).to be true
    end

    it "returns false for different docs" do
      expect(described_class.equivalent?(doc_a, doc_b)).to be false
    end
  end

  describe "accepts bytes" do
    it "compares from raw PDF bytes" do
      io_a = StringIO.new
      doc_a.write(io: io_a)
      io_b = StringIO.new
      doc_b.write(io: io_b)

      report = described_class.compare(io_a.string, io_b.string)
      expect(report.equivalent?).to be false
    end
  end

  describe "Report" do
    it "has a similarity score" do
      report = described_class.compare(doc_a, doc_b)
      expect(report.similarity).to be_a(Float)
      expect(report.similarity).to be > 0.0
      expect(report.similarity).to be <= 1.0
    end

    it "has a summary string" do
      report = described_class.compare(doc_a, doc_b)
      expect(report.summary).to include("DIFFERENT")
    end

    it "reports font differences" do
      doc_with_times = Pdfrb::Document.new.tap do |doc|
        font = doc.fonts.add("Times-Roman")
        doc.pages.add.canvas.text("Test", at: [72, 720], font: font, size: 12)
      end

      report = described_class.compare(doc_a, doc_with_times)
      added = report.font_diff[:added]
      removed = report.font_diff[:removed]
      expect(added + removed).not_to be_empty
    end

    it "detects metadata differences" do
      doc_a.metadata.title = "Document A"
      doc_b.metadata.title = "Document B"

      report = described_class.compare(doc_a, doc_b)
      expect(report.metadata_diff).not_to be_empty
    end

    it "serialises to hash" do
      report = described_class.compare(doc_a, doc_b)
      h = report.to_h
      expect(h).to include(:equivalent, :similarity, :page_count_delta)
    end
  end

  describe "outline comparison" do
    it "detects added bookmarks" do
      doc_without = Pdfrb::Document.new.tap { |d| d.pages.add }
      doc_with = Pdfrb::Document.new.tap do |doc|
        doc.pages.add
        doc.outline.add("Chapter 1")
        doc.outline.build!
      end

      report = described_class.compare(doc_without, doc_with)
      expect(report.outline_diff[:added]).to include("Chapter 1")
    end
  end
end
