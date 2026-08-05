# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Signature and DocMDP types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Signature do
    let(:sig) do
      doc.add({
        Type: :Sig, Filter: :"Adobe.PPKLite",
        SubFilter: :"adbe.pkcs7.detached",
        Contents: "\x00".b * 1024,
        ByteRange: [0, 100, 200, 50],
        Name: "Alice",
        Reason: "Approval",
        M: "D:20260101120000"
      }, type: described_class)
    end

    it "exposes signer metadata" do
      expect(sig.name).to eq("Alice")
      expect(sig.reason).to eq("Approval")
    end

    it "classifies subfilter" do
      expect(sig.pkcs7_detached?).to be true
      expect(sig.pkcs1?).to be false
    end

    it "validates byte range" do
      expect(sig.has_byte_range?).to be true
    end

    it "parses signing time" do
      time = sig.signed_time
      expect(time&.year).to eq(2026)
    end
  end

  describe Pdfrb::Model::Type::SigFieldLock do
    it "decodes lock action" do
      lock = doc.add({ Action: :Include, Fields: ["field1", "field2"] },
                     type: described_class)
      expect(lock.include_locked?).to be true
      expect(lock.locked_field_names).to eq(["field1", "field2"])
    end

    it "recognises All action" do
      lock = doc.add({ Action: :All }, type: described_class)
      expect(lock.all_locked?).to be true
      expect(lock.locked_field_names).to eq([])
    end
  end

  describe Pdfrb::Model::Type::SigFieldSeedValue do
    it "decodes required-filter flag" do
      sv = doc.add({ Filter: :"Adobe.PPKLite", F: 0x100 },
                   type: described_class)
      expect(sv.required_filter?).to be true
    end

    it "decodes all 3 modification flags" do
      sv = doc.add({ F: 7 }, type: described_class)
      expect(sv.add_rev_info?).to be true
      expect(sv.add_doc_mdp?).to be true
      expect(sv.add_field_mdp?).to be true
    end
  end

  describe Pdfrb::Model::Type::DocMDPTransformParameters do
    it "decodes modification level" do
      p1 = doc.add({ Type: :TransformParams, P: 1, V: 1.2 }, type: described_class)
      expect(p1.no_changes_allowed?).to be true
      p3 = doc.add({ Type: :TransformParams, P: 3 }, type: described_class)
      expect(p3.annotations_allowed?).to be true
    end
  end
end

RSpec.describe "Action media types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::ActionRendition do
    it "decodes operation code" do
      action = doc.add({ Type: :Action, S: :Rendition, OP: 0 },
                       type: described_class)
      expect(action.play?).to be true
      expect(action.stop?).to be false
    end

    it "detects pause/resume" do
      action = doc.add({ Type: :Action, S: :Rendition, OP: 2 },
                       type: described_class)
      expect(action.pause?).to be true
    end
  end

  describe Pdfrb::Model::Type::ActionThread do
    it "detects first/last bead" do
      a1 = doc.add({ Type: :Action, S: :Thread, D: 0 }, type: described_class)
      expect(a1.first_bead?).to be true
      a2 = doc.add({ Type: :Action, S: :Thread, D: -1 }, type: described_class)
      expect(a2.last_bead?).to be true
    end
  end
end
