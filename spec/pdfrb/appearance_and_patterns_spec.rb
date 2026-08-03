# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Appearance::Generator do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:generator) { described_class.new(doc) }

  it "generates appearance for a text field" do
    field = doc.form.add_text_field("name", page: page, rect: [10, 10, 200, 30])
    generator.text_field(field, value: "John Doe", font_name: :Helv, font_size: 10)

    ap = field.value[:AP]
    expect(ap).not_to be_nil
    expect(ap[:N]).to be_a(Pdfrb::Model::Reference)
  end

  it "generates appearance for a checked checkbox" do
    field = doc.form.add_checkbox("agree", page: page, rect: [10, 10, 30, 30], checked: true)
    generator.checkbox(field, checked: true)

    ap = field.value[:AP]
    expect(ap[:N]).to be_a(Hash)
    expect(ap[:N][:Yes]).to be_a(Pdfrb::Model::Reference)
    expect(field.value[:AS]).to eq(:Yes)
  end

  it "generates appearance for an unchecked checkbox" do
    field = doc.form.add_checkbox("disagree", page: page, rect: [10, 10, 30, 30])
    generator.checkbox(field, checked: false)

    ap = field.value[:AP]
    expect(ap[:N][:Off]).to be_a(Pdfrb::Model::Reference)
    expect(field.value[:AS]).to eq(:Off)
  end

  it "generates appearance for a combo box" do
    field = doc.form.add_combo("country", page: page, rect: [10, 10, 200, 30],
                                          options: ["US", "UK"], value: "US")
    generator.combo(field, value: "US")

    ap = field.value[:AP]
    expect(ap[:N]).to be_a(Pdfrb::Model::Reference)
  end

  it "generates appearance for a push button" do
    field = doc.form.add_text_field("btn", page: page, rect: [10, 10, 100, 40])
    field.value[:FT] = :Btn
    generator.button(field, label: "Submit")

    ap = field.value[:AP]
    expect(ap).not_to be_nil
  end

  it "handles nil rect gracefully" do
    field = doc.add({ Type: :Annot, Subtype: :Widget },
                    type: Pdfrb::Model::Type::Annotation)
    generator.text_field(field, value: "test")
    expect(field.value[:AP]).to be_nil
  end
end

RSpec.describe Pdfrb::Content::TilingPattern do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }

  it "creates a tiling pattern stream" do
    pattern = described_class.new(bbox: [0, 0, 20, 20], x_step: 20, y_step: 20)
    name = pattern.register_on(doc, page) do |canvas|
      canvas.rectangle(0, 0, 10, 10)
      canvas.stroke
    end

    expect(name).to match(/\AP\d+\z/)
    resources = page.value[:Resources]
    expect(resources[:Pattern][name]).to be_a(Pdfrb::Model::Reference)
  end

  it "supports constant spacing tiling type" do
    pattern = described_class.new(tiling_type: 1, bbox: [0, 0, 8, 8])
    name = pattern.register_on(doc, page) { |c| c.line(0, 0, 8, 8) }

    ref = page.value[:Resources][:Pattern][name]
    pattern_obj = doc.object(ref)
    expect(pattern_obj.value[:TilingType]).to eq(1)
    expect(pattern_obj.value[:PatternType]).to eq(1)
  end

  it "supports no-distortion tiling type" do
    pattern = described_class.new(tiling_type: 2, bbox: [0, 0, 16, 16])
    name = pattern.register_on(doc, page) { |c| c.line_width = 1 }

    ref = page.value[:Resources][:Pattern][name]
    pattern_obj = doc.object(ref)
    expect(pattern_obj.value[:TilingType]).to eq(2)
  end

  it "supports uncolored patterns" do
    pattern = described_class.new(paint_type: 2, bbox: [0, 0, 4, 4])
    name = pattern.register_on(doc, page) { |c| c.line_width = 1 }

    ref = page.value[:Resources][:Pattern][name]
    pattern_obj = doc.object(ref)
    expect(pattern_obj.value[:PaintType]).to eq(2)
  end

  it "auto-increments pattern names" do
    p1 = described_class.new.register_on(doc, page) { |c| c.line_width = 1 }
    p2 = described_class.new.register_on(doc, page) { |c| c.line_width = 1 }
    expect(p1).to eq(:P1)
    expect(p2).to eq(:P2)
  end
end

RSpec.describe Pdfrb::Conformance::PdfA do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "A-1 flags object streams" do
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    doc.add({ Type: :ObjStm, N: 1, First: 0 },
            type: Pdfrb::Model::Cos::Stream)

    result = described_class.validate(doc, level: :a1b)
    v = result.violations.find { |x| x.rule_id == "a1-2" }
    expect(v).not_to be_nil
  end

  it "A-1 rejects PDF versions above 1.4" do
    doc.version = "1.7"
    result = described_class.validate(doc, level: :a1b)
    v = result.violations.find { |x| x.rule_id == "a1-3" }
    expect(v).not_to be_nil
  end

  it "A-1 accepts PDF 1.4" do
    doc.version = "1.4"
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    result = described_class.validate(doc, level: :a1b)
    v = result.violations.find { |x| x.rule_id == "a1-3" }
    expect(v).to be_nil
  end

  it "A-1 rule set has at least 3 A1-specific rules" do
    a1_specific = described_class::A1.rules.reject { |r| described_class::SHARED.rules.include?(r) }
    expect(a1_specific.length).to be >= 3
  end
end
