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

  describe "#set_value" do
    it "stores the value and regenerates appearance" do
      field = doc.form.add_text_field("name", page: page, rect: [10, 10, 100, 30])
      doc.form.set_value("name", "Alice")

      expect(field.value[:V]).to eq("Alice")
      expect(field.value[:AP]).not_to be_nil
    end

    it "normalizes checkbox values to :Yes/:Off" do
      field = doc.form.add_checkbox("opt", page: page, rect: [0, 0, 20, 20])
      doc.form.set_value("opt", true)
      expect(field.value[:V]).to eq(:Yes)
      doc.form.set_value("opt", false)
      expect(field.value[:V]).to eq(:Off)
    end

    it "returns nil for unknown field" do
      expect(doc.form.set_value("missing", "x")).to be_nil
    end
  end

  describe "#get_value" do
    it "returns the stored value" do
      doc.form.add_text_field("name", page: page, rect: [0, 0, 100, 20], value: "Bob")
      expect(doc.form.get_value("name")).to eq("Bob")
    end

    it "returns nil for unknown field" do
      expect(doc.form.get_value("missing")).to be_nil
    end
  end

  describe "#flatten!" do
    it "removes /Fields from /AcroForm" do
      doc.form.add_text_field("a", page: page, rect: [0, 0, 100, 20])
      doc.form.add_text_field("b", page: page, rect: [0, 0, 100, 20])
      expect(doc.form.count).to eq(2)

      doc.form.flatten!

      acroform = doc.catalog.value[:AcroForm]
      expect(acroform[:Fields]).to be_nil
      expect(acroform[:NeedAppearances]).to be_nil
    end

    it "stamps appearance into page /Resources /XObject" do
      doc.form.add_text_field("name", page: page, rect: [50, 50, 200, 70])
      doc.form.set_value("name", "Carol")
      doc.form.flatten!

      resources = page.value[:Resources]
      expect(resources).to be_a(Pdfrb::Model::Cos::Dictionary)
      xobjects = resources.value[:XObject]
      expect(xobjects).not_to be_nil
      expect(xobjects.length).to be_positive
    end

    it "emits Do operator in page content for text fields" do
      doc.form.add_text_field("name", page: page, rect: [50, 50, 200, 70])
      doc.form.set_value("name", "Dan")
      doc.form.flatten!

      contents = page.value[:Contents]
      contents_obj = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
      stream = contents_obj.is_a?(Pdfrb::Model::Cos::Stream) ? contents_obj.stream : nil
      expect(stream).to include(" Do")
    end

    it "removes widget from page /Annots" do
      field = doc.form.add_text_field("name", page: page, rect: [0, 0, 100, 20])
      widget_oid = field.oid
      doc.form.flatten!

      annots = page.value[:Annots] || []
      oids = annots.map { |r| r.is_a?(Pdfrb::Model::Reference) ? r.oid : nil }
      expect(oids).not_to include(widget_oid)
    end

    it "handles checkbox flatten with multi-state /AP" do
      doc.form.add_checkbox("agree", page: page, rect: [0, 0, 20, 20])
      doc.form.set_value("agree", true)
      expect { doc.form.flatten! }.not_to raise_error
    end
  end

  describe "#remove_field" do
    it "removes from /AcroForm /Fields" do
      field = doc.form.add_text_field("temp", page: page, rect: [0, 0, 100, 20])
      expect(doc.form.count).to eq(1)

      doc.form.remove_field(field)
      expect(doc.form.count).to eq(0)
    end

    it "removes widget from page /Annots" do
      field = doc.form.add_text_field("temp", page: page, rect: [0, 0, 100, 20])
      widget_oid = field.oid
      doc.form.remove_field(field)

      annots = page.value[:Annots] || []
      oids = annots.map { |r| r.is_a?(Pdfrb::Model::Reference) ? r.oid : nil }
      expect(oids).not_to include(widget_oid)
    end

    it "returns nil when acroform is absent" do
      field = doc.add({ Type: :Annot, Subtype: :Widget, T: "x" },
                      type: Pdfrb::Model::Type::Annotation)
      expect(doc.form.remove_field(field)).to be_nil
    end
  end

  describe "#field_names" do
    it "lists all field names" do
      doc.form.add_text_field("first", page: page, rect: [0, 0, 100, 20])
      doc.form.add_text_field("second", page: page, rect: [0, 0, 100, 20])
      expect(doc.form.field_names).to contain_exactly("first", "second")
    end
  end
end
