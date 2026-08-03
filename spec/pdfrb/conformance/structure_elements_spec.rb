# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::StructureElements do
  describe ".standard_types" do
    it "includes all ISO 32000-2 structure types" do
      types = described_class.standard_types
      expect(types).to include(:Document, :Part, :Art, :H1, :P, :L, :LI,
                               :Table, :TR, :TH, :TD, :Figure, :Formula,
                               :TOC, :TOCI, :Ruby, :Span)
    end
  end

  describe ".standard?" do
    it "returns true for standard types" do
      expect(described_class.standard?(:H1)).to be true
      expect(described_class.standard?(:Figure)).to be true
    end

    it "returns false for non-standard types" do
      expect(described_class.standard?(:MyHeading)).to be false
      expect(described_class.standard?(:CustomBox)).to be false
    end
  end

  describe ".expected_children" do
    it "returns expected child types for List" do
      expect(described_class.expected_children(:L)).to eq([:LI])
    end

    it "returns expected child types for Table" do
      children = described_class.expected_children(:Table)
      expect(children).to include(:TR, :THead, :TBody, :TFoot)
    end

    it "returns nil for types with no child restrictions" do
      expect(described_class.expected_children(:P)).to be_nil
    end
  end

  describe ".required_attributes" do
    it "requires Alt or ActualText for Figure" do
      attrs = described_class.required_attributes(:Figure)
      expect(attrs).to include(:Alt, :ActualText)
    end

    it "requires Alt or ActualText for Formula" do
      attrs = described_class.required_attributes(:Formula)
      expect(attrs).to include(:Alt, :ActualText)
    end
  end
end

RSpec.describe Pdfrb::Conformance::PdfUA do
  # rubocop:disable RSpec/DescribeClass
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  def setup_tagged_doc
    doc.catalog.value[:Lang] = "en-US"
    mark = doc.add({ Marked: true })
    doc.catalog.value[:MarkInfo] = Pdfrb::Model::Reference.new(mark.oid, mark.gen)
    root = doc.add({ Type: :StructTreeRoot })
    doc.catalog.value[:StructTreeRoot] = Pdfrb::Model::Reference.new(root.oid, root.gen)
    root
  end

  def add_child(parent, type, **extra)
    child = doc.add({ Type: :StructElem, S: type }.merge!(extra))
    parent.value[:K] ||= []
    parent.value[:K] << Pdfrb::Model::Reference.new(child.oid, child.gen)
    child
  end

  it "detects non-standard structure types without role mapping" do
    root = setup_tagged_doc
    add_child(root, :MyCustomType)

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-9" }
    expect(v).not_to be_nil
  end

  it "passes non-standard types that are role-mapped" do
    root = setup_tagged_doc
    root.value[:RoleMap] = { MyCustomType: :P }
    add_child(root, :MyCustomType)

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-9" }
    expect(v).to be_nil
  end

  it "detects List without LI children" do
    root = setup_tagged_doc
    list = add_child(root, :L)
    add_child(list, :P) # wrong child type

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-10" }
    expect(v).not_to be_nil
  end

  it "passes List with LI children" do
    root = setup_tagged_doc
    list = add_child(root, :L)
    add_child(list, :LI)

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-10" }
    expect(v).to be_nil
  end

  it "detects Table without TR children" do
    root = setup_tagged_doc
    table = add_child(root, :Table)
    add_child(table, :P) # wrong child

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-11" }
    expect(v).not_to be_nil
  end

  it "passes Table with TR children" do
    root = setup_tagged_doc
    table = add_child(root, :Table)
    add_child(table, :TR)

    result = described_class.validate(doc)
    v = result.violations.find { |x| x.rule_id == "ua-11" }
    expect(v).to be_nil
  end

  it "has at least 11 rules in the PDF/UA ruleset" do
    expect(described_class::RULESET.rules.length).to be >= 11
  end
end
# rubocop:enable RSpec/DescribeClass
