# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Form do
  let(:doc) do
    Pdfrb::Document.new.tap { |d| d.pages.add }
  end

  let(:page) { doc.pages.first }

  it "enables AcroForm on the catalog" do
    doc.form.enable!

    acroform = doc.catalog.value[:AcroForm]
    expect(acroform[:Fields]).to eq([])
    expect(acroform[:NeedAppearances]).to be true
  end

  it "is idempotent" do
    first = doc.form.enable!
    second = doc.form.enable!
    expect(second).to be(first)
  end

  it "creates a text field with correct type" do
    field = doc.form.add_text_field("username", page: page,
                                                rect: [50, 700, 250, 720])

    expect(field.value[:FT]).to eq(:Tx)
    expect(field.value[:T]).to eq("username")
    expect(field.value[:Rect]).to eq([50, 700, 250, 720])
  end

  it "sets text field value and multiline flag" do
    field = doc.form.add_text_field("comments", page: page,
                                                rect: [50, 600, 300, 700],
                                                value: "Hello", multiline: true)

    expect(field.value[:V]).to eq("Hello")
    expect(field.value[:Ff] & 0x1000).to be_positive
  end

  it "creates a checkbox" do
    field = doc.form.add_checkbox("agree", page: page,
                                           rect: [50, 750, 65, 765], checked: true)

    expect(field.value[:FT]).to eq(:Btn)
    expect(field.value[:V]).to eq(:Yes)
  end

  it "creates an unchecked checkbox" do
    field = doc.form.add_checkbox("disagree", page: page,
                                              rect: [50, 750, 65, 765])

    expect(field.value[:V]).to eq(:Off)
  end

  it "creates a combo box with options" do
    field = doc.form.add_combo("country", page: page,
                                          rect: [50, 650, 200, 670],
                                          options: ["US", "UK", "JP"],
                                          value: "US")

    expect(field.value[:FT]).to eq(:Ch)
    expect(field.value[:Opt]).to eq(["US", "UK", "JP"])
    expect(field.value[:V]).to eq("US")
  end

  it "links fields to pages via /P and /Annots" do
    field = doc.form.add_text_field("name", page: page,
                                            rect: [50, 700, 250, 720])

    expect(field.value[:P]).to eq(
      Pdfrb::Model::Reference.new(page.oid, page.gen)
    )

    annots = page.value[:Annots]
    expect(annots).to include(
      Pdfrb::Model::Reference.new(field.oid, field.gen)
    )
  end

  it "tracks field count" do
    expect(doc.form.count).to eq(0)

    doc.form.add_text_field("a", page: page, rect: [0, 0, 10, 10])
    doc.form.add_checkbox("b", page: page, rect: [0, 0, 10, 10])

    expect(doc.form.count).to eq(2)
  end

  it "finds a field by name" do
    doc.form.add_text_field("email", page: page, rect: [0, 0, 10, 10])

    found = doc.form.find("email")
    expect(found.value[:T]).to eq("email")
  end

  it "round-trips through serialization" do
    doc.form.add_text_field("addr", page: page, rect: [50, 700, 300, 720])

    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    acroform = reparsed.catalog.value[:AcroForm]
    expect(acroform).not_to be_nil

    fields = acroform[:Fields]
    expect(fields.length).to eq(1)
  end
end
