# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 19 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Dss do
    it "exposes certificates, ocsp, crls" do
      cert = doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      dss = doc.add(
        {
          Type: :DSS,
          Certs: [Pdfrb::Model::Reference.new(cert.oid, 0)],
          OCSPs: [],
          CRLs: [],
        },
        type: described_class
      )
      expect(dss.type).to eq(:DSS)
      expect(dss.certificates(doc).length).to eq(1)
      expect(dss.ocsp_responses(doc)).to eq([])
      expect(dss.crls(doc)).to eq([])
    end

    it "enumerates VRI entries" do
      vri = doc.add({ Type: :VRI, Cert: [] },
                    type: Pdfrb::Model::Type::Vri)
      dss = doc.add(
        { VRI: { "ABC123" => Pdfrb::Model::Reference.new(vri.oid, 0) } },
        type: described_class
      )
      entries = dss.each_vri(doc).to_a
      expect(entries.length).to eq(1)
      expect(entries.first[0]).to eq("ABC123")
      expect(entries.first[1]).to be_a(Pdfrb::Model::Type::Vri)
    end

    it "looks up VRI by signature hash" do
      vri = doc.add({ Type: :VRI }, type: Pdfrb::Model::Type::Vri)
      dss = doc.add(
        { VRI: { "DEADBEEF" => Pdfrb::Model::Reference.new(vri.oid, 0) } },
        type: described_class
      )
      found = dss.vri_for("DEADBEEF", doc)
      expect(found).not_to be_nil
      expect(dss.vri_for("UNKNOWN", doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::DPartRoot do
    it "exposes root_node, record_level, node_name_list" do
      part = doc.add({ Type: :DPart }, type: Pdfrb::Model::Type::DPart)
      root = doc.add(
        {
          Type: :DPartRoot,
          DPartRootNode: Pdfrb::Model::Reference.new(part.oid, 0),
          RecordLevel: 2,
          NodeNameList: [:Recipient, :Job],
        },
        type: described_class
      )
      expect(root.type).to eq(:DPartRoot)
      expect(root.root_node(doc)).to be_a(Pdfrb::Model::Type::DPart)
      expect(root.record_level).to eq(2)
      expect(root.node_name_list).to eq([:Recipient, :Job])
    end
  end

  describe Pdfrb::Model::Type::DPart do
    it "leaf part exposes start/end pages" do
      page = doc.pages.add
      part = doc.add(
        {
          Type: :DPart,
          Start: Pdfrb::Model::Reference.new(page.oid, page.gen),
          End: Pdfrb::Model::Reference.new(page.oid, page.gen),
        },
        type: described_class
      )
      expect(part.leaf?).to be true
      expect(part.start_page(doc)).not_to be_nil
      expect(part.end_page(doc)).not_to be_nil
    end

    it "branch part exposes child_parts" do
      part = doc.add(
        { Type: :DPart, DParts: [[{ Type: :DPart }, { Type: :DPart }]] },
        type: described_class
      )
      expect(part.leaf?).to be false
      expect(part.child_parts).not_to be_nil
    end
  end
end
