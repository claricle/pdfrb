# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfA do
  describe "deep preflight" do
    let(:doc) { Pdfrb::Document.new }

    def set_version(d, v)
      d.version = v
    end

    before do
      doc.pages.add
      set_version(doc, "1.4")
    end

    it "flags JavaScript names tree" do
      doc.catalog.value[:Names] = { JavaScript: { Names: ["Alert", :ref] } }
      result = described_class.validate(doc, level: :a1b)
      expect(result.violations.map(&:rule_id)).to include("preflight-1")
    end

    it "does not flag JavaScript-free catalog" do
      result = described_class.validate(doc, level: :a1b)
      expect(result.violations.map(&:rule_id)).not_to include("preflight-1")
    end

    it "flags PostScript XObjects" do
      doc.add({ Type: :XObject, Subtype: :PS },
              type: Pdfrb::Model::Cos::Stream)
      result = described_class.validate(doc, level: :a1b)
      expect(result.violations.map(&:rule_id)).to include("preflight-2")
    end

    it "flags encryption" do
      doc.trailer[:Encrypt] = Pdfrb::Model::Reference.new(999, 0)
      result = described_class.validate(doc, level: :a1b)
      expect(result.violations.map(&:rule_id)).to include("preflight-4")
    end

    it "A-1 forbids EmbeddedFile" do
      doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      result = described_class.validate(doc, level: :a1b)
      expect(result.violations.map(&:rule_id)).to include("preflight-3-a1a2")
    end

    it "A-3 does not flag EmbeddedFile" do
      doc.version = "1.6"
      doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      result = described_class.validate(doc, level: :a3b)
      expect(result.violations.map(&:rule_id)).not_to include("preflight-3-a1a2")
    end

    it "A-4 forbids EmbeddedFile" do
      doc.version = "2.0"
      doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      result = described_class.validate(doc, level: :a4)
      expect(result.violations.map(&:rule_id)).to include("preflight-3-a1a2")
    end
  end
end
