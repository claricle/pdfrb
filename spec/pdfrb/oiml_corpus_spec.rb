# frozen_string_literal: true

require "spec_helper"
require "stringio"

OIML_FIXTURES_DIR = File.join(__dir__, "..", "fixtures", "pdfs", "oiml")

RSpec.describe "OIML FOP-generated PDF corpus", unless: Dir.exist?(OIML_FIXTURES_DIR) do
  pending "copy OIML PDFs to spec/fixtures/pdfs/oiml/ to enable these tests"
end

RSpec.describe "OIML FOP-generated PDF corpus", if: Dir.exist?(OIML_FIXTURES_DIR) do
  fixtures = Dir.glob(File.join(OIML_FIXTURES_DIR, "*.pdf")).sort

  it "has at least 20 fixture PDFs" do
    expect(fixtures.length).to be >= 20
  end

  fixtures.each do |path|
    name = File.basename(path, ".pdf")

    it "#{name} opens and reads" do
      bytes = File.binread(path)
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      expect(doc.catalog).to be_a(Pdfrb::Model::Type::Catalog)
    end

    it "#{name} has pages" do
      bytes = File.binread(path)
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      expect(doc.pages.count).to be_positive
    end

    it "#{name} round-trips without losing pages" do
      bytes = File.binread(path)
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      original_count = doc.pages.count
      out = StringIO.new
      doc.write(io: out)
      reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
      expect(reloaded.pages.count).to eq(original_count)
    end
  end
end
