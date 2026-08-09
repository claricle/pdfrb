# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfX do
  let(:doc) { Pdfrb::Document.new }

  before do
    doc.pages.add
  end

  describe "PDF/X-6" do
    it "fails when version is below 2.0" do
      doc.version = "1.7"
      result = described_class.validate(doc, level: :x6)
      expect(result.violations.map(&:rule_id)).to include("x6-1")
    end

    it "passes the version check at 2.0" do
      doc.version = "2.0"
      result = described_class.validate(doc, level: :x6)
      expect(result.violations.map(&:rule_id)).not_to include("x6-1")
    end

    it "warns when no OutputIntent with /S /GTS_PDFX" do
      doc.version = "2.0"
      result = described_class.validate(doc, level: :x6)
      expect(result.violations.map(&:rule_id)).to include("x6-2")
    end

    it "passes when GTS_PDFX output intent is present" do
      doc.version = "2.0"
      intent = doc.add({ Type: :OutputIntent, S: :GTS_PDFX },
                       type: Pdfrb::Model::Cos::Dictionary)
      doc.catalog.value[:OutputIntents] = [
        Pdfrb::Model::Reference.new(intent.oid, intent.gen),
      ]
      result = described_class.validate(doc, level: :x6)
      expect(result.violations.map(&:rule_id)).not_to include("x6-2")
    end

    it "is selected via level: :x6" do
      doc.version = "1.4"
      result = described_class.validate(doc, level: :x6)
      expect(result.profile).to eq("PDF/X-6")
    end
  end
end
