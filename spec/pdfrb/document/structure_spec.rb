# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Structure do
  let(:doc) do
    Pdfrb::Document.new.tap do |d|
      d.pages.add
    end
  end

  it "enables tagging by creating StructTreeRoot and MarkInfo" do
    doc.structure.enable!

    catalog = doc.catalog
    expect(catalog.value[:StructTreeRoot]).to be_a(Pdfrb::Model::Reference)
    expect(catalog.value[:MarkInfo]).to be_a(Pdfrb::Model::Reference)
  end

  it "is idempotent" do
    first = doc.structure.enable!
    second = doc.structure.enable!
    expect(second.oid).to eq(first.oid)
  end

  it "adds top-level elements with structure types" do
    elem = doc.structure.add_element(:H1, title: "Chapter 1")

    expect(elem.value[:Type]).to eq(:StructElem)
    expect(elem.value[:S]).to eq(:H1)
    expect(elem.value[:T]).to eq("Chapter 1")
  end

  it "links elements in a parent-child hierarchy" do
    section = doc.structure.add_element(:Div)
    heading = doc.structure.add_child(section, :H1)
    para = doc.structure.add_child(section, :P)

    section_ref = section.value[:K]
    expect(section_ref).to include(
      Pdfrb::Model::Reference.new(heading.oid, heading.gen),
      Pdfrb::Model::Reference.new(para.oid, para.gen)
    )

    expect(heading.value[:P]).to eq(
      Pdfrb::Model::Reference.new(section.oid, section.gen)
    )
  end

  it "supports role mapping for custom types" do
    doc.structure.map_role(:Heading1, :H1)

    role_map = doc.structure.root.value[:RoleMap]
    expect(role_map[:Heading1]).to eq(:H1)
  end

  it "serializes and round-trips the structure tree" do
    doc.structure.add_element(:Document) do |doc_elem|
      doc.structure.add_child(doc_elem, :H1, title: "Intro")
    end

    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    catalog = reparsed.catalog
    struct_ref = catalog.value[:StructTreeRoot]
    expect(struct_ref).to be_a(Pdfrb::Model::Reference)

    root = reparsed.object(struct_ref)
    expect(root.value[:Type]).to eq(:StructTreeRoot)

    mark_info_ref = catalog.value[:MarkInfo]
    mark_info = reparsed.object(mark_info_ref)
    expect(mark_info.value[:Marked]).to be true
  end

  it "preserves alt text for accessibility" do
    figure = doc.structure.add_element(:Figure, alt: "A diagram of the system")
    expect(figure.value[:Alt]).to eq("A diagram of the system")
  end
end
