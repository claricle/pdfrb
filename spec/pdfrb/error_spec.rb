# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb do
  it "exposes a version string" do
    expect(Pdfrb::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it "loads lazily without raising on the autoload tree" do
    expect { Pdfrb::VERSION }.not_to raise_error
    expect { Pdfrb::PdfConstants::HEADER_PREFIX }.not_to raise_error
  end
end

RSpec.describe Pdfrb::Error do
  it "is the root of the error hierarchy" do
    expect(Pdfrb::ParseError < Pdfrb::Error).to be(true)
    expect(Pdfrb::LexError < Pdfrb::ParseError).to be(true)
    expect(Pdfrb::SyntaxError < Pdfrb::ParseError).to be(true)
    expect(Pdfrb::MalformedPdfError < Pdfrb::ParseError).to be(true)
    expect(Pdfrb::SerializeError < Pdfrb::Error).to be(true)
    expect(Pdfrb::FilterError < Pdfrb::Error).to be(true)
    expect(Pdfrb::EncryptionError < Pdfrb::Error).to be(true)
    expect(Pdfrb::UnsupportedVersionError < Pdfrb::Error).to be(true)
    expect(Pdfrb::ObjectReferenceError < Pdfrb::Error).to be(true)
    expect(Pdfrb::ValidationError < Pdfrb::Error).to be(true)
  end

  describe Pdfrb::ParseError do
    it "carries a source position" do
      err = Pdfrb::ParseError.new("oops", source_position: [12, 5])
      expect(err.source_position).to eq([12, 5])
      expect(err.message).to eq("oops")
    end
  end

  describe Pdfrb::MalformedPdfError do
    it "reports whether recovery succeeded" do
      recovered = Pdfrb::MalformedPdfError.new("fixed", recovered: true)
      unrecovered = Pdfrb::MalformedPdfError.new("broken", recovered: false)
      expect(recovered).to be_recovered
      expect(unrecovered).not_to be_recovered
    end
  end

  describe Pdfrb::FilterError do
    it "carries the failing filter name" do
      err = Pdfrb::FilterError.new("bad zlib", filter_name: "FlateDecode")
      expect(err.filter_name).to eq("FlateDecode")
    end
  end

  describe Pdfrb::UnsupportedVersionError do
    it "carries the unsupported version" do
      err = Pdfrb::UnsupportedVersionError.new("nope", version: "9.9")
      expect(err.version).to eq("9.9")
    end
  end

  describe Pdfrb::ObjectReferenceError do
    it "carries oid and gen" do
      err = Pdfrb::ObjectReferenceError.new("dangling", oid: 17, gen: 0)
      expect(err.oid).to eq(17)
      expect(err.gen).to eq(0)
    end
  end

  describe Pdfrb::ValidationError do
    it "carries the field name and predicate name" do
      err = Pdfrb::ValidationError.new("bad", field_name: "Rotate",
                                             predicate_name: "fn:Eval")
      expect(err.field_name).to eq("Rotate")
      expect(err.predicate_name).to eq("fn:Eval")
    end
  end
end

RSpec.describe Pdfrb::PdfConstants do
  it "declares the PDF header magic" do
    expect(Pdfrb::PdfConstants::HEADER_PREFIX).to eq("%PDF-")
  end

  it "lists versions oldest to newest, ending at 2.0" do
    expect(Pdfrb::PdfConstants::PDF_VERSIONS.last).to eq("2.0")
    expect(Pdfrb::PdfConstants::PDF_VERSIONS).to eq(
      %w[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 2.0]
    )
  end

  it "recognises the structural keywords" do
    keywords = Pdfrb::PdfConstants::KEYWORDS
    %w[obj endobj stream endstream xref startxref trailer true false null].each do |kw|
      expect(keywords).to include(kw)
    end
  end
end

RSpec.describe Pdfrb::Configuration do
  it "deep-merges user overrides into the defaults" do
    config = Pdfrb::Configuration.new("source.recover_malformed" => false)
    expect(config["source.recover_malformed"]).to be(false)
    expect(config["document.auto_decrypt"]).to be(true)
  end

  it "is frozen" do
    expect(Pdfrb::Configuration.new).to be_frozen
  end
end
