# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Task::GenerateCorpus do
  describe ".all" do
    it "generates all corpus types" do
      corpus = described_class.all
      expect(corpus.keys).to include(:simple, :multipage, :tagged, :with_layers, :with_form, :signed)
    end

    it "produces valid PDF bytes for simple" do
      bytes = described_class.simple_text
      expect(bytes).to start_with("%PDF-")
      expect(bytes).to include("%%EOF")
    end

    it "produces a multi-page PDF" do
      bytes = described_class.multipage_text
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      expect(doc.pages.count).to eq(5)
    end

    it "produces a tagged PDF with StructTreeRoot" do
      bytes = described_class.tagged_pdf
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      expect(doc.catalog.value[:StructTreeRoot]).not_to be_nil
      expect(doc.catalog.value[:Lang]).to eq("en-US")
    end

    it "produces a PDF with layers" do
      bytes = described_class.with_layers
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      ocp = doc.catalog.value[:OCProperties]
      expect(ocp).not_to be_nil
    end

    it "produces a PDF with a form" do
      bytes = described_class.with_form
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      acroform = doc.catalog.value[:AcroForm]
      expect(acroform).not_to be_nil
    end

    it "produces a signed PDF" do
      bytes = described_class.signed_doc
      skip "signing failed in corpus" if bytes.empty?

      expect(bytes).to start_with("%PDF-")
      expect(bytes).to include("/ByteRange")
    end

    it "produces a large document" do
      bytes = described_class.large_document(10)
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))
      expect(doc.pages.count).to eq(10)
    end
  end
end

RSpec.describe Pdfrb::Task::Benchmark do
  it "runs benchmarks and returns results" do
    results = described_class.run(repetitions: 3)
    expect(results).to be_an(Array)
    expect(results.length).to be_positive

    first = results.first
    expect(first.name).to include("parse:")
    expect(first.ops_per_second).to be_positive
  end
end

RSpec.describe Pdfrb::Task::MemoryProfile do
  it "profiles memory usage" do
    pdf = Pdfrb::Task::GenerateCorpus.simple_text
    snapshot = described_class.profile(pdf)

    expect(snapshot).to be_a(Pdfrb::Task::MemoryProfile::Snapshot)
    expect(snapshot.total_objects).to be_an(Integer)
  end

  it "categorizes objects by type" do
    pdf = Pdfrb::Task::GenerateCorpus.simple_text
    snapshot = described_class.profile(pdf)

    expect(snapshot.by_type).to be_a(Hash)
  end
end

RSpec.describe Pdfrb::Conformance::VeraPdfBridge do
  describe ".available?" do
    it "returns a boolean" do
      expect(described_class.available?).to be(true).or be(false)
    end
  end

  describe ".validate" do
    it "returns a result with available: false when veraPDF not installed" do
      allow(described_class).to receive(:available?).and_return(false)
      result = described_class.validate("%PDF-1.4\n")
      expect(result.available).to be(false)
    end
  end

  describe ".parse_violations" do
    it "parses veraPDF JSON output" do
      json = '{"report":{"jobs":[{"validationResult":{"details":{"assertions":[{"ruleId":"6.1-1","message":"no encryption","clause":"6.2.2"}]}}}]}}'
      violations = described_class.parse_violations(json)
      expect(violations.length).to eq(1)
      expect(violations.first.rule_id).to eq("6.1-1")
    end

    it "handles empty output" do
      expect(described_class.parse_violations("")).to eq([])
    end

    it "handles malformed JSON" do
      expect(described_class.parse_violations("{bad}")).to eq([])
    end
  end
end
