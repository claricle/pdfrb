# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfVT do
  let(:doc) { Pdfrb::Document.new }

  def vt_ready!
    doc.pages.add
    doc.catalog.value[:MarkInfo] = { Marked: true }
    intent = doc.add({ Type: :OutputIntent, S: :GTS_PDFX },
                     type: Pdfrb::Model::Cos::Dictionary)
    doc.catalog.value[:OutputIntents] = [
      Pdfrb::Model::Reference.new(intent.oid, intent.gen),
    ]
    dpart = doc.add({ Type: :DPartRoot },
                    type: Pdfrb::Model::Cos::Dictionary)
    doc.catalog.value[:DPartRoot] =
      Pdfrb::Model::Reference.new(dpart.oid, dpart.gen)
  end

  it "fails when /MarkInfo /Marked is missing" do
    doc.pages.add
    result = described_class.validate(doc, level: :vt1)
    expect(result.violations.map(&:rule_id)).to include("vt-1")
  end

  it "fails when OutputIntents is missing" do
    doc.pages.add
    doc.catalog.value[:MarkInfo] = { Marked: true }
    result = described_class.validate(doc, level: :vt1)
    expect(result.violations.map(&:rule_id)).to include("vt-2")
  end

  it "fails when DPartRoot is missing" do
    doc.pages.add
    doc.catalog.value[:MarkInfo] = { Marked: true }
    intent = doc.add({ Type: :OutputIntent, S: :GTS_PDFX },
                     type: Pdfrb::Model::Cos::Dictionary)
    doc.catalog.value[:OutputIntents] = [
      Pdfrb::Model::Reference.new(intent.oid, intent.gen),
    ]
    result = described_class.validate(doc, level: :vt1)
    expect(result.violations.map(&:rule_id)).to include("vt-3")
  end

  it "passes when all PDF/VT requirements are met" do
    vt_ready!
    result = described_class.validate(doc, level: :vt1)
    expect(result.violations.map(&:rule_id)).not_to include("vt-1", "vt-2", "vt-3", "vt-4")
  end

  it "flags encryption" do
    vt_ready!
    doc.trailer[:Encrypt] = Pdfrb::Model::Reference.new(999, 0)
    result = described_class.validate(doc, level: :vt1)
    expect(result.violations.map(&:rule_id)).to include("vt-4")
  end

  it "VT-2 level is selectable" do
    vt_ready!
    result = described_class.validate(doc, level: :vt2)
    expect(result.profile).to eq("PDF/VT-2")
  end

  it "VT-1 level is selectable" do
    vt_ready!
    result = described_class.validate(doc, level: :vt1)
    expect(result.profile).to eq("PDF/VT-1")
  end
end
