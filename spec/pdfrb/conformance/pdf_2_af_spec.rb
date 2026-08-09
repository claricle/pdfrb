# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::Pdf2AF do
  let(:doc) { Pdfrb::Document.new }

  def add_filespec_with_af(rel: :Source, uf: "doc.xml", with_ef: true)
    ef_stream = nil
    if with_ef
      ef_stream = doc.add({ Type: :EmbeddedFile, Subtype: "application/xml" },
                          type: Pdfrb::Model::Cos::Stream)
    end
    ef_value = with_ef ? { UF: Pdfrb::Model::Reference.new(ef_stream.oid, 0) } : {}
    doc.add({
      Type: :FileSpec, UF: uf,
      AFRelationship: rel,
      EF: ef_value
    }, type: Pdfrb::Model::Cos::Dictionary)
  end

  def add_container_with_af(af_entries)
    container = doc.add({ Type: :Page }, type: Pdfrb::Model::Type::Page)
    container.value[:AF] = af_entries
    container
  end

  it "passes when all AF entries have valid AFRelationship" do
    fs = add_filespec_with_af(rel: :Source)
    add_container_with_af([Pdfrb::Model::Reference.new(fs.oid, 0)])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("af-1", "af-2")
  end

  it "flags AF entries missing AFRelationship" do
    fs = doc.add({ Type: :FileSpec, UF: "x" },
                 type: Pdfrb::Model::Cos::Dictionary)
    add_container_with_af([Pdfrb::Model::Reference.new(fs.oid, 0)])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("af-1")
  end

  it "flags invalid AFRelationship values" do
    fs = doc.add({ Type: :FileSpec, UF: "x", AFRelationship: :Bogus },
                 type: Pdfrb::Model::Cos::Dictionary)
    add_container_with_af([Pdfrb::Model::Reference.new(fs.oid, 0)])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("af-2")
  end

  it "flags FileSpec without UF or EF" do
    fs = doc.add({ Type: :FileSpec, AFRelationship: :Source },
                 type: Pdfrb::Model::Cos::Dictionary)
    add_container_with_af([Pdfrb::Model::Reference.new(fs.oid, 0)])
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("af-3")
  end

  it "warns when EmbeddedFile has no Subtype" do
    doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).to include("af-4")
  end

  it "passes when EmbeddedFile has Subtype" do
    doc.add({ Type: :EmbeddedFile, Subtype: "application/pdf" },
            type: Pdfrb::Model::Cos::Stream)
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("af-4")
  end

  it "accepts all six allowed relationships" do
    %i[Source Data Alternative Supplement EncryptedPayload Unspecified].each do |rel|
      fs = add_filespec_with_af(rel: rel)
      add_container_with_af([Pdfrb::Model::Reference.new(fs.oid, 0)])
    end
    result = described_class.validate(doc)
    expect(result.violations.map(&:rule_id)).not_to include("af-2")
  end
end
