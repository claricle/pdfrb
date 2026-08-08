# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Task::RegenerateAppearances do
  let(:doc) { Pdfrb::Document.new }
  let(:page) { doc.pages.add }

  it "regenerates appearance for a text field" do
    field = doc.form.add_text_field("name", page: page, rect: [0, 0, 100, 30])
    field.value[:V] = "Alice"

    count = described_class.call(doc)
    expect(count).to be_positive
    expect(field.value[:AP]).not_to be_nil
  end

  it "regenerates appearance for a checkbox" do
    field = doc.form.add_checkbox("agree", page: page, rect: [0, 0, 20, 20])
    field.value[:V] = :Yes

    count = described_class.call(doc)
    expect(count).to be_positive
    expect(field.value[:AP]).not_to be_nil
  end

  it "regenerates appearance for a combo box" do
    field = doc.form.add_combo("choice", page: page, rect: [0, 0, 100, 20],
                                         options: %w[A B C])
    field.value[:V] = "B"

    count = described_class.call(doc)
    expect(count).to be_positive
  end

  it "respects only: filter" do
    doc.form.add_text_field("name", page: page, rect: [0, 0, 100, 20])
    check = doc.form.add_checkbox("agree", page: page, rect: [0, 0, 20, 20])
    check.value[:V] = :Yes

    count = described_class.call(doc, only: [:Btn])
    expect(count).to eq(1)
    expect(check.value[:AP]).not_to be_nil
  end

  it "clears NeedAppearances on AcroForm" do
    doc.form.enable!
    expect(doc.catalog.value[:AcroForm][:NeedAppearances]).to be(true)

    described_class.call(doc)
    expect(doc.catalog.value[:AcroForm][:NeedAppearances]).to be_nil
  end

  it "iterates widget annotations across pages" do
    page2 = doc.pages.add
    doc.form.add_text_field("a", page: page, rect: [0, 0, 50, 20])
    doc.form.add_text_field("b", page: page2, rect: [0, 0, 50, 20])

    count = described_class.call(doc)
    expect(count).to eq(2)
  end

  it "returns 0 when no widgets present" do
    count = described_class.call(doc)
    expect(count).to eq(0)
  end
end
