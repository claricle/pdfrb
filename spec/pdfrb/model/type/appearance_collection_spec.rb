# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Appearance and font file types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::AppearanceCharacteristics do
    it "exposes widget appearance fields" do
      ac = doc.add({ BG: [1, 1, 0], CA: "Click", R: 90 },
                   type: described_class)
      expect(ac.background_color).to eq([1, 1, 0])
      expect(ac.caption).to eq("Click")
      expect(ac.rotation).to eq(90)
      expect(ac.has_background?).to be true
      expect(ac.has_caption?).to be true
    end
  end

  describe Pdfrb::Model::Type::Appearance do
    it "checks normal/rollover/down presence" do
      ap = doc.add({ N: {}, R: {} }, type: described_class)
      expect(ap.has_normal?).to be true
      expect(ap.has_rollover?).to be true
      expect(ap.has_down?).to be false
    end
  end

  describe Pdfrb::Model::Type::FontFile2 do
    it "detects TrueType magic" do
      stream = doc.add({ Length1: 4 }, type: described_class)
      stream.stream = "\x00\x01\x00\x00".b
      expect(stream.truetype?).to be true
      expect(stream.opentype?).to be false
    end

    it "detects OpenType magic" do
      stream = doc.add({}, type: described_class)
      stream.stream = "OTTO".b
      expect(stream.opentype?).to be true
    end
  end

  describe Pdfrb::Model::Type::FontFile3 do
    it "classifies /Subfilter variants" do
      stream = doc.add({ Subtype: :CIDFontType0C },
                       type: described_class)
      expect(stream.cid_font_type0?).to be true
    end

    it "detects OpenType subtype" do
      stream = doc.add({ Subtype: :OpenType }, type: described_class)
      expect(stream.open_type?).to be true
      expect(stream.truetype?).to be false
    end
  end
end

RSpec.describe "Collection / Portfolio types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Collection do
    it "exposes portfolio fields" do
      coll = doc.add({ Schema: { Name: { N: "Name", Subtype: :Text } },
                       View: :D },
                     type: described_class)
      expect(coll.has_schema?).to be true
      expect(coll.default_view).to eq(:D)
    end
  end

  describe Pdfrb::Model::Type::CollectionField do
    it "classifies field type" do
      f = doc.add({ N: "Title", Subtype: :Text }, type: described_class)
      expect(f.text_field?).to be true
      expect(f.number_field?).to be false
    end
  end

  describe Pdfrb::Model::Type::CollectionSchema do
    it "enumerates schema fields" do
      s = doc.add({ Name: { N: "Name" }, Size: { N: "Size" } },
                  type: described_class)
      expect(s.field_count).to eq(2)
      expect(s.fields.sort).to eq(%i[Name Size])
    end
  end

  describe Pdfrb::Model::Type::CollectionSort do
    it "decodes descending flag" do
      s = doc.add({ S: :Name, A: true }, type: described_class)
      expect(s.field_name).to eq(:Name)
      expect(s.descending?).to be true
    end
  end

  describe Pdfrb::Model::Type::BoxColorInfo do
    it "is empty by default" do
      bci = doc.add({}, type: described_class)
      expect(bci.empty?).to be true
    end

    it "exposes per-box styles" do
      bci = doc.add({ CropBox: { C: [1, 0, 0] } },
                    type: described_class)
      expect(bci.crop_box_style).to eq(C: [1, 0, 0])
      expect(bci.empty?).to be false
    end
  end
end
