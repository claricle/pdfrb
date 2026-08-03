# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::PdfA do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "A-1 rejects versions above 1.4" do
    doc.version = "1.7"
    result = described_class.validate(doc, level: :a1b)
    v = result.violations.find { |x| x.rule_id == "a1-3" }
    expect(v).not_to be_nil
  end

  it "A-2 rejects PDF 2.0" do
    doc.version = "2.0"
    result = described_class.validate(doc, level: :a2b)
    v = result.violations.find { |x| x.rule_id == "a2-3" }
    expect(v).not_to be_nil
  end

  it "A-2 accepts PDF 1.7" do
    doc.version = "1.7"
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    result = described_class.validate(doc, level: :a2b)
    v = result.violations.find { |x| x.rule_id == "a2-3" }
    expect(v).to be_nil
  end

  it "A-4 requires PDF 2.0" do
    doc.version = "1.7"
    result = described_class.validate(doc, level: :a4)
    v = result.violations.find { |x| x.rule_id == "a4-1" }
    expect(v).not_to be_nil
  end

  it "complete version matrix is consistent" do
    # A-1: ≤1.4, A-2: ≤1.7, A-3: ≤1.7, A-4: ≥2.0
    doc.version = "1.4"
    r1 = described_class.validate(doc, level: :a1b)
    expect(r1.violations.find { |x| x.rule_id == "a1-3" }).to be_nil

    doc.version = "1.7"
    r2 = described_class.validate(doc, level: :a2b)
    expect(r2.violations.find { |x| x.rule_id == "a2-3" }).to be_nil

    doc.version = "2.0"
    r4 = described_class.validate(doc, level: :a4)
    expect(r4.violations.find { |x| x.rule_id == "a4-1" }).to be_nil
  end
end

RSpec.describe Pdfrb::Content::Canvas do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "tracks fonts used by text" do
    canvas.text("Hello", at: [72, 720], font: :Helv, size: 12)
    expect(canvas.used_fonts).to include(:Helv)
    expect(canvas.used_fonts[:Helv]).to eq(12)
  end

  it "tracks multiple fonts" do
    canvas.text("A", at: [0, 0], font: :Helv, size: 10)
    canvas.text("B", at: [0, 0], font: :Cour, size: 8)
    expect(canvas.used_fonts.keys).to contain_exactly(:Helv, :Cour)
  end

  it "tracks XObjects used by draw_image" do
    canvas.draw_image(:Im1, at: [0, 0], width: 100, height: 100)
    expect(canvas.used_xobjects).to include(:Im1)
  end

  it "populate_resources writes to page Resources" do
    canvas.text("Hello", at: [0, 0], font: :Helv, size: 12)
    canvas.draw_image(:Im1, at: [0, 0], width: 100, height: 100)
    canvas.populate_resources!(page)

    resources = page.value[:Resources]
    expect(resources).to be_a(Hash)
    expect(resources[:Font]).to include(:Helv)
    expect(resources[:XObject]).to include(:Im1)
  end

  it "populate_resources is idempotent" do
    canvas.text("Hello", at: [0, 0], font: :Helv, size: 12)
    canvas.populate_resources!(page)
    canvas.populate_resources!(page)
    expect(page.value[:Resources][:Font][:Helv]).not_to be_nil
  end
end
