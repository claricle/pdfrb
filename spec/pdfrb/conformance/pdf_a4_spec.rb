# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfA do
  describe "PDF/A-4 profile" do
    let(:pdf4_doc) do
      Pdfrb::Document.new.tap do |d|
        d.version = "2.0"
        d.pages.add
      end
    end

    it "registers as a RuleSet" do
      expect(described_class::A4).to be_a(Pdfrb::Conformance::RuleSet)
    end

    it "inherits shared rules from PDF/A" do
      shared_ids = described_class::SHARED.rules.map(&:id)
      a4_ids = described_class::A4.rules.map(&:id)
      shared_ids.each { |id| expect(a4_ids).to include(id) }
    end

    it "requires PDF 2.0 version header" do
      pdf4_doc.version = "1.7"
      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-1" }
      expect(v).not_to be_nil
      expect(v.severity).to eq(:error)
    end

    it "accepts PDF 2.0 header" do
      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-1" }
      expect(v).to be_nil
    end

    it "detects filespecs missing /AFRelationship" do
      filespec = pdf4_doc.add(
        { Type: :Filespec, F: "report.pdf" },
        type: Pdfrb::Model::Cos::Dictionary
      )
      _ = filespec

      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-2" }
      expect(v).not_to be_nil
    end

    it "passes filespec with /AFRelationship" do
      pdf4_doc.add(
        {
          Type: :Filespec,
          F: "report.pdf",
          AFRelationship: :Source,
        },
        type: Pdfrb::Model::Cos::Dictionary
      )

      result = described_class.validate(pdf4_doc, level: :a4)
      af_rel = result.violations.find { |x| x.rule_id == "a4-2" }
      expect(af_rel).to be_nil
    end

    it "detects annotations without appearance streams" do
      pdf4_doc.add(
        {
          Type: :Annot,
          Subtype: :Square,
          Rect: [50, 50, 100, 100],
        },
        type: Pdfrb::Model::Cos::Dictionary
      )

      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-3" }
      expect(v).not_to be_nil
    end

    it "exempts Link annotations from appearance requirement" do
      pdf4_doc.add(
        {
          Type: :Annot,
          Subtype: :Link,
          Rect: [50, 50, 100, 100],
        },
        type: Pdfrb::Model::Cos::Dictionary
      )

      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-3" }
      expect(v).to be_nil
    end

    it "exempts zero-area annotations (Rect with 1==3 and 2==4)" do
      pdf4_doc.add(
        {
          Type: :Annot,
          Subtype: :Square,
          Rect: [50, 50, 50, 50],
        },
        type: Pdfrb::Model::Cos::Dictionary
      )

      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-3" }
      expect(v).to be_nil
    end

    it "warns about missing trailer /ID" do
      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-4" }
      expect(v).not_to be_nil
      expect(v.severity).to eq(:warning)
    end

    it "warns about missing /Metadata" do
      result = described_class.validate(pdf4_doc, level: :a4)
      v = result.violations.find { |x| x.rule_id == "a4-5" }
      expect(v).not_to be_nil
    end

    it "is selectable via profiles(:a4)" do
      expect(described_class.profiles[:a4]).to be(described_class::A4)
    end
  end
end
