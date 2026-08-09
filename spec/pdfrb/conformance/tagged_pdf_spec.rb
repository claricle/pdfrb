# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::TaggedPdf do
  let(:doc) { Pdfrb::Document.new }

  def add_struct_tree(elements: [])
    tree_root = doc.add({ Type: :StructTreeRoot }, type: Pdfrb::Model::Cos::Dictionary)
    elements.each do |elem|
      kid = doc.add(elem, type: Pdfrb::Model::Cos::Dictionary)
      tree_root.value[:K] ||= []
      tree_root.value[:K] << Pdfrb::Model::Reference.new(kid.oid, kid.gen)
    end
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(tree_root.oid, tree_root.gen)
    doc.catalog.value[:MarkInfo] = { Marked: true }
    tree_root
  end

  it "fails when /MarkInfo is missing" do
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("tag-1")
  end

  it "fails when /StructTreeRoot is missing" do
    doc.catalog.value[:MarkInfo] = { Marked: true }
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("tag-2")
  end

  it "passes when MarkInfo and StructTreeRoot are both present and empty" do
    add_struct_tree
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("tag-1", "tag-2")
  end

  it "warns when a Figure has no Alt or ActualText" do
    add_struct_tree(elements: [{ Type: :StructElem, S: :Figure }])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("tag-4")
  end

  it "passes when a Figure has Alt" do
    add_struct_tree(elements: [{ Type: :StructElem, S: :Figure, Alt: "diagram" }])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("tag-4")
  end

  it "warns when Table has no TR children" do
    table = doc.add({ Type: :StructElem, S: :Table },
                    type: Pdfrb::Model::Cos::Dictionary)
    bad_child = doc.add({ Type: :StructElem, S: :P },
                        type: Pdfrb::Model::Cos::Dictionary)
    table.value[:K] = [Pdfrb::Model::Reference.new(bad_child.oid, bad_child.gen)]

    root = doc.add({ Type: :StructTreeRoot }, type: Pdfrb::Model::Cos::Dictionary)
    root.value[:K] = [Pdfrb::Model::Reference.new(table.oid, table.gen)]
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)
    doc.catalog.value[:MarkInfo] = { Marked: true }

    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("tag-5")
  end

  it "passes when Table has TR children" do
    table = doc.add({ Type: :StructElem, S: :Table },
                    type: Pdfrb::Model::Cos::Dictionary)
    tr = doc.add({ Type: :StructElem, S: :TR },
                 type: Pdfrb::Model::Cos::Dictionary)
    table.value[:K] = [Pdfrb::Model::Reference.new(tr.oid, tr.gen)]

    root = doc.add({ Type: :StructTreeRoot }, type: Pdfrb::Model::Cos::Dictionary)
    root.value[:K] = [Pdfrb::Model::Reference.new(table.oid, table.gen)]
    doc.catalog.value[:StructTreeRoot] =
      Pdfrb::Model::Reference.new(root.oid, root.gen)
    doc.catalog.value[:MarkInfo] = { Marked: true }

    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("tag-5")
  end

  it "warns on non-standard structure type" do
    add_struct_tree(elements: [{ Type: :StructElem, S: :Bogus }])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("tag-3")
  end

  it "passes for standard types like P, H1, Div" do
    add_struct_tree(elements: [
                      { Type: :StructElem, S: :P },
                      { Type: :StructElem, S: :H1 },
                      { Type: :StructElem, S: :Div },
                    ])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("tag-3")
  end
end
