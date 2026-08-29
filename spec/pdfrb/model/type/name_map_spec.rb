# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Type::NameMap do
  let(:map_class) do
    Class.new(Pdfrb::Model::Cos::Dictionary) do
      include Pdfrb::Model::Type::NameMap
    end
  end

  it "looks up by Symbol or String and adds under a Symbol" do
    map = map_class.new
    key = map.add("F1", { Subtype: :Image })
    expect(key).to eq(:F1)
    expect(map[:F1]).not_to be_nil
    expect(map["F1"]).not_to be_nil
    expect(map.names).to eq([:F1])
  end

  it "enumerates entries" do
    map = map_class.new
    map.add(:A, 1)
    map.add(:B, 2)
    expect(map.each_entry.to_a).to eq([[:A, 1], [:B, 2]])
  end

  it "returns nil for unknown names" do
    expect(map_class.new[:missing]).to be_nil
  end

  it "mixes into every resource-map type" do
    [
      Pdfrb::Model::Type::ColorSpaceMap, Pdfrb::Model::Type::ColorantsDict,
      Pdfrb::Model::Type::DestsMap, Pdfrb::Model::Type::XObjectMap,
      Pdfrb::Model::Type::PatternMap, Pdfrb::Model::Type::ShadingMap,
      Pdfrb::Model::Type::GraphicsStateParameterMap,
      Pdfrb::Model::Type::RoleMap, Pdfrb::Model::Type::RoleMapNS,
      Pdfrb::Model::Type::ClassMap, Pdfrb::Model::Type::Solidities,
      Pdfrb::Model::Type::VRIMap, Pdfrb::Model::Type::SubjectDN,
      Pdfrb::Model::Type::Extensions, Pdfrb::Model::Type::CryptFilterMap,
      Pdfrb::Model::Type::CryptFilterPublicKeyMap,
      Pdfrb::Model::Type::CharProcMap
    ].each do |klass|
      expect(klass.ancestors).to include(described_class), klass.name
    end
  end
end
