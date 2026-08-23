# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 25 function/halftone/media mappings" do
  let(:doc) { Pdfrb::Document.new }

  describe "function family" do
    it "maps FunctionSampled to FunctionType0" do
      fn = doc.add({ FunctionType: 0, Domain: [0, 1], Range: [0, 1, 0, 1, 0, 1],
                     Size: [2, 2, 2], BitsPerSample: 8 },
                   type: Pdfrb::Model::Type::FunctionSampled)
      expect(fn.class.field(:Size).arlington).not_to be_nil
      expect(fn.class.field(:BitsPerSample).arlington).not_to be_nil
    end

    it "maps FunctionExponential to FunctionType2" do
      fn = doc.add({ FunctionType: 2, Domain: [0, 1], C0: [0], C1: [1], N: 1 },
                   type: Pdfrb::Model::Type::FunctionExponential)
      expect(fn.class.field(:C0).arlington).not_to be_nil
      expect(fn.class.field(:N).arlington).not_to be_nil
    end

    it "maps FunctionStitching to FunctionType3" do
      fn = doc.add({ FunctionType: 3, Domain: [0, 1], Functions: [],
                     Bounds: [0.5], Encode: [0, 1, 0, 1] },
                   type: Pdfrb::Model::Type::FunctionStitching)
      expect(fn.class.field(:Functions).arlington).not_to be_nil
      expect(fn.class.field(:Bounds).arlington).not_to be_nil
    end

    it "maps FunctionPostScript to FunctionType4" do
      fn = doc.add({ FunctionType: 4, Domain: [0, 1], Range: [0, 1] },
                   type: Pdfrb::Model::Type::FunctionPostScript)
      expect(fn.class.field(:Domain).arlington).not_to be_nil
    end
  end

  describe "halftone family" do
    it "maps all five halftone types" do
      {
        Pdfrb::Model::Type::HalftoneType1 => [:HalftoneType1, :Frequency],
        Pdfrb::Model::Type::HalftoneType5 => [:HalftoneType5, :Default],
        Pdfrb::Model::Type::HalftoneType6 => [:HalftoneType6, :Width],
        Pdfrb::Model::Type::HalftoneType10 => [:HalftoneType10, :Xsquare],
        Pdfrb::Model::Type::HalftoneType16 => [:HalftoneType16, :Width2],
      }.each do |klass, (tsv, key)|
        ht = doc.add({ HalftoneType: klass.name.split("::").last.sub("HalftoneType", "").to_i },
                     type: klass)
        expect(Pdfrb::Model::Type.arlington_registry[tsv.to_s]).to eq(klass)
        expect(ht.class.field(key).arlington).not_to be_nil, "#{tsv}: #{key}"
      end
    end
  end

  describe "rich media family" do
    it "maps all eleven RichMedia classes" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        RichMediaActivation: :Condition,
        RichMediaAnimation: :PlayCount,
        RichMediaCommand: :C,
        RichMediaConfiguration: :Instances,
        RichMediaContent: :Assets,
        RichMediaCuePoint: :Subtype,
        RichMediaDeactivation: :Condition,
        RichMediaInstance: :Asset,
        RichMediaPresentation: :Style,
        RichMediaSettings: :Activation,
        RichMediaWindow: :Height,
      }.each do |klass_name, key|
        klass = Pdfrb::Model::Type.const_get(klass_name)
        expect(registry[klass_name.to_s]).to eq(klass)
        expect(klass.field(key).arlington).not_to be_nil, "#{klass_name}: #{key}"
      end
    end
  end

  describe "media family" do
    it "maps offsets, players, screen parameters, and criteria" do
      registry = Pdfrb::Model::Type.arlington_registry
      expect(registry["MediaOffsetTime"]).to eq(Pdfrb::Model::Type::MediaOffsetTime)
      expect(registry["MediaOffsetFrame"]).to eq(Pdfrb::Model::Type::MediaOffsetFrame)
      expect(registry["MediaOffsetMarker"]).to eq(Pdfrb::Model::Type::MediaOffsetMarker)
      expect(registry["MediaPlayerInfo"]).to eq(Pdfrb::Model::Type::MediaPlayerInfo)
      expect(registry["MediaPlayers"]).to eq(Pdfrb::Model::Type::MediaPlayers)
      expect(registry["MediaScreenParameters"]).to eq(Pdfrb::Model::Type::MediaScreenParameters)
      expect(registry["MediaCriteria"]).to eq(Pdfrb::Model::Type::MediaCriteria)

      criteria = doc.add({ R: [640, 480] }, type: Pdfrb::Model::Type::MediaCriteria)
      expect(criteria.class.field(:R).arlington).not_to be_nil
    end
  end
end
