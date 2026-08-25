# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Type::PageTreeNodeRoot do
  let(:doc) { Pdfrb::Document.new }

  it "shadows the inherited required /Parent with not-required" do
    expect(Pdfrb::Model::Type::PageTreeNode.field(:Parent).required).to be_truthy
    expect(described_class.field(:Parent).required).to be_falsey

    names = described_class.each_field.to_a.map(&:first)
    expect(names.count(:Parent)).to eq(1)
  end

  it "reports no violation for a root without /Parent" do
    root = doc.add({ Type: :Pages, Kids: [], Count: 0 }, type: described_class)
    expect(root.validate.to_a).to eq([])
    expect(root).to be_root
  end

  it "still flags interior nodes that lack /Parent" do
    node = doc.add({ Type: :Pages, Kids: [], Count: 0 },
                   type: Pdfrb::Model::Type::PageTreeNode)
    expect(node.validate.to_a.map(&:first))
      .to include("Required field Parent is missing")
  end
end
