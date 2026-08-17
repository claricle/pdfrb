# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 20 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::AddActionPageObject do
    it "exposes on_open and on_close actions" do
      open_action = doc.add({ Type: :Action, S: :URI },
                            type: Pdfrb::Model::Type::Action)
      aa = doc.add(
        { O: Pdfrb::Model::Reference.new(open_action.oid, 0) },
        type: described_class
      )
      expect(aa.on_open(doc)).not_to be_nil
      expect(aa.on_close(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::BorderStyle do
    it "defaults to width 1, solid" do
      bs = doc.add({}, type: described_class)
      expect(bs.width).to eq(1)
      expect(bs.style).to eq(:S)
      expect(bs).to be_solid
    end

    it "parses dashed style with dash array" do
      bs = doc.add({ W: 2.5, S: :D, D: [3, 2] }, type: described_class)
      expect(bs.width).to eq(2.5)
      expect(bs.style).to eq(:D)
      expect(bs.dash).to eq([3, 2])
      expect(bs).to be_dashed
    end

    it "distinguishes beveled/inset/underline" do
      expect(doc.add({ S: :B }, type: described_class)).to be_beveled
      expect(doc.add({ S: :I }, type: described_class)).to be_inset
      expect(doc.add({ S: :U }, type: described_class)).to be_underline
    end
  end

  describe Pdfrb::Model::Type::BorderEffect do
    it "parses cloudy style with intensity" do
      be = doc.add({ S: :C, I: 1.5 }, type: described_class)
      expect(be.style).to eq(:C)
      expect(be.intensity).to eq(1.5)
      expect(be.cloudy?).to be true
      expect(be.inset?).to be false
    end

    it "handles absent /S" do
      be = doc.add({ I: 2 }, type: described_class)
      expect(be.intensity).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::CIDSystemInfo do
    it "parses registry, ordering, supplement" do
      csi = doc.add(
        { Registry: "Adobe", Ordering: "Japan1", Supplement: 5 },
        type: described_class
      )
      expect(csi.registry).to eq("Adobe")
      expect(csi.ordering).to eq("Japan1")
      expect(csi.supplement).to eq(5)
      expect(csi.complete?).to be true
      expect(csi.identity?).to be false
    end

    it "detects identity encoding" do
      csi = doc.add(
        { Registry: "Adobe", Ordering: "Identity", Supplement: 0 },
        type: described_class
      )
      expect(csi.identity?).to be true
    end
  end
end
