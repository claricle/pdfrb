# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 23 destination + crypt specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::DestinationXYZ do
    it "exposes left/top/zoom coordinates" do
      dest = doc.add([3, :XYZ, 36, 720, 2.0], type: described_class)
      expect(dest.display_type).to eq(:XYZ)
      expect(dest.page_number).to eq(3)
      expect(dest).to be_page_number
      expect(dest.left).to eq(36)
      expect(dest.top).to eq(720)
      expect(dest.zoom).to eq(2.0)
      expect(dest).to be_xyz
      expect(described_class.arlington_definition).not_to be_nil
      expect(described_class.element_field(4)).not_to be_nil
      expect(Pdfrb::Model::Type.arlington_registry["DestXYZArray"]).to eq(described_class)
    end

    it "detects position-retaining form" do
      dest = doc.add([0, :XYZ, nil, nil, nil], type: described_class)
      expect(dest).to be_retains_position
    end
  end

  describe Pdfrb::Model::Type::DestinationFit do
    it "exposes the fit display type" do
      dest = doc.add([0, :Fit], type: described_class)
      expect(dest.display_type).to eq(:Fit)
      expect(dest).to be_fit
      expect(dest).not_to be_xyz
    end
  end

  describe Pdfrb::Model::Type::DestinationFitH do
    it "exposes the top coordinate" do
      dest = doc.add([1, :FitH, 792], type: described_class)
      expect(dest).to be_fit_h
      expect(dest.top).to eq(792)
    end
  end

  describe Pdfrb::Model::Type::DestinationFitR do
    it "exposes the fit rectangle" do
      dest = doc.add([2, :FitR, 10, 20, 300, 400], type: described_class)
      expect(dest).to be_fit_r
      expect(dest.left).to eq(10)
      expect(dest.bottom).to eq(20)
      expect(dest.right).to eq(300)
      expect(dest.top).to eq(400)
    end
  end

  describe "structure destination variants" do
    it "XYZ struct detects structure references" do
      dest = doc.add(["structref12", :XYZ, nil, nil, nil],
                     type: Pdfrb::Model::Type::DestinationXYZStruct)
      expect(dest).to be_struct_ref
      expect(dest).not_to be_page_number
    end

    it "Fit/FitH/FitR struct variants map their TSVs" do
      %i[DestinationFitStruct DestinationFitHStruct DestinationFitRStruct].each do |klass_name|
        klass = Pdfrb::Model::Type.const_get(klass_name)
        expect(klass.arlington_definition).not_to be_nil, klass_name.to_s
        expect(klass.element_field(0)).not_to be_nil, klass_name.to_s
      end
      dest = doc.add(["s1", :FitR, 0, 0, 100, 100],
                     type: Pdfrb::Model::Type::DestinationFitRStruct)
      expect(dest.display_type).to eq(:FitR)
      expect(dest).to be_struct_ref
    end
  end

  describe Pdfrb::Model::Type::DestinationDict do
    it "wraps D and SD forms" do
      dict = doc.add({ D: [0, :Fit] }, type: described_class)
      expect(dict.d).not_to be_nil
      expect(dict).not_to be_structure_destination

      sd = doc.add({ SD: [0, :Fit] }, type: described_class)
      expect(sd).to be_structure_destination
    end
  end

  describe Pdfrb::Model::Type::DestsMap do
    it "adds and looks up named destinations" do
      map = doc.add({}, type: described_class)
      map.add(:intro, [0, :XYZ, 0, 792, nil])
      expect(map[:intro]).not_to be_nil
      expect(map.names).to include(:intro)
      expect(map.names.size).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::CryptFilter do
    it "gains Arlington metadata and keeps cipher predicates" do
      cf = doc.add({ Type: :CryptFilter, CFM: :AESV2, Length: 16 },
                   type: described_class)
      expect(cf.cipher_method).to eq(:AESV2)
      expect(cf).to be_aes_v2
      expect(cf).not_to be_v2
      expect(cf.class.field(:CFM).arlington).not_to be_nil
      expect(cf.class.field(:AuthEvent)).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::CryptFilterMap do
    it "gains the wildcard TSV mapping" do
      map = doc.add({ StdCF: { CFM: :AESV2 } }, type: described_class)
      expect(map.class.field(:*)).not_to be_nil
      expect(map.filter_for(:StdCF)).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::CryptFilterPublicKey do
    it "gains Arlington metadata for Recipients" do
      cf = doc.add({ Recipients: ["\x00\x01".b], EncryptMetadata: true },
                   type: described_class)
      expect(cf.recipients).not_to be_nil
      expect(cf.class.field(:Recipients).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::CryptFilterPublicKeyMap do
    it "gains the wildcard TSV mapping" do
      map = doc.add({ DefaultCryptFilter: { Recipients: [] } },
                    type: described_class)
      expect(map.class.field(:*)).not_to be_nil
      expect(map.filter_for(:DefaultCryptFilter)).not_to be_nil
    end
  end

  it "resolves named destinations end-to-end" do
    dests = doc.add({}, type: Pdfrb::Model::Type::DestsMap)
    dests.add(:top, [0, :XYZ, nil, 792, nil])
    doc.catalog.value[:Dests] = dests

    expect(doc.destinations[:top]).not_to be_nil
  end
end
