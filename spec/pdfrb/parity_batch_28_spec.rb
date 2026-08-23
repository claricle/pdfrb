# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 28 viewer/DeviceN/measure mappings" do
  let(:doc) { Pdfrb::Document.new }

  describe "registry wiring" do
    it "registers all mapped classes under their TSVs" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::ViewerPreferences => "ViewerPreferences",
        Pdfrb::Model::Type::MarkInformation => "MarkInfo",
        Pdfrb::Model::Type::IconFit => "IconFit",
        Pdfrb::Model::Type::PagePieceInfo => "PagePiece",
        Pdfrb::Model::Type::URIDict => "URI",
        Pdfrb::Model::Type::URLAlias => "URLAlias",
        Pdfrb::Model::Type::URTransformParameters => "URTransformParameters",
        Pdfrb::Model::Type::DeviceN => "DeviceNDict",
        Pdfrb::Model::Type::DeviceNProcess => "DeviceNProcess",
        Pdfrb::Model::Type::DeviceNMixingHints => "DeviceNMixingHints",
        Pdfrb::Model::Type::Separation => "Separation",
        Pdfrb::Model::Type::Measure => "MeasureRL",
        Pdfrb::Model::Type::GeospatialMeasure => "MeasureGEO",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end
  end

  describe Pdfrb::Model::Type::ViewerPreferences do
    it "materializes viewer preference metadata" do
      vp = doc.add({ HideToolbar: false, NumCopies: 1, ViewArea: :CropBox },
                   type: described_class)
      expect(vp.class.field(:HideToolbar).arlington).not_to be_nil
      expect(vp.class.field(:NumCopies).arlington).not_to be_nil
      expect(vp.class.field(:PrintScaling).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::MarkInformation do
    it "materializes MarkInfo metadata" do
      mi = doc.add({ Marked: true, Suspects: false }, type: described_class)
      expect(mi.class.field(:Marked).arlington).not_to be_nil
      expect(mi.class.field(:Suspects).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::IconFit do
    it "materializes icon fit metadata" do
      fit = doc.add({ SW: :A, S: :P, A: [0.5, 0.5] }, type: described_class)
      expect(fit.class.field(:SW).arlington).not_to be_nil
      expect(fit.class.field(:A).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::PagePieceInfo do
    it "maps the wildcard PagePiece TSV" do
      ppi = doc.add({ Prepress: { LastModified: "D:20240101000000Z" } },
                    type: described_class)
      expect(ppi.class.field(:*)).not_to be_nil
    end
  end

  describe "URI family" do
    it "materializes URI and URLAlias metadata" do
      uri = doc.add({ Base: "https://example.org/" },
                    type: Pdfrb::Model::Type::URIDict)
      expect(uri.class.field(:Base).arlington).not_to be_nil

      alias_dict = doc.add({ U: "https://example.org/alt" },
                           type: Pdfrb::Model::Type::URLAlias)
      expect(alias_dict.class.field(:U).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::URTransformParameters do
    it "materializes rights-management transform metadata" do
      ur = doc.add({ Document: ["FullSave"] }, type: described_class)
      expect(ur.class.field(:Document).arlington).not_to be_nil
      expect(ur.class.field(:Form).arlington).not_to be_nil
      expect(ur.class.field(:Annots).arlington).not_to be_nil
    end
  end

  describe "DeviceN family" do
    it "materializes DeviceN attribute metadata" do
      dn = doc.add({ Subtype: :NChannel, Colorants: { Gold: nil } },
                   type: Pdfrb::Model::Type::DeviceN)
      expect(dn).to be_nchannel
      expect(dn.class.field(:Subtype).arlington).not_to be_nil
      expect(dn.class.field(:Colorants).arlington).not_to be_nil
      expect(dn.class.field(:MixingHints).arlington).not_to be_nil

      process = doc.add({ ColorSpace: :DeviceCMYK, Colorants: {},
                          TintTransform: {} },
                        type: Pdfrb::Model::Type::DeviceNProcess)
      expect(process.class.field(:ColorSpace).arlington).not_to be_nil

      hints = doc.add({ Solidities: { Cyan: 0.9 } },
                      type: Pdfrb::Model::Type::DeviceNMixingHints)
      expect(hints.class.field(:Solidities).arlington).not_to be_nil

      sep = doc.add({ ColorSpace: :DeviceCMYK, DeviceColorant: :Gold,
                      Pages: 3 },
                    type: Pdfrb::Model::Type::Separation)
      expect(sep.class.field(:ColorSpace).arlington).not_to be_nil
      expect(sep.class.field(:DeviceColorant).arlington).not_to be_nil
      expect(sep.device_colorant).to eq(:Gold)
      expect(sep.pages).to eq(3)
    end
  end

  describe "measure family" do
    it "maps rectilinear measure and adds geospatial measure" do
      rl = doc.add({ Type: :Measure, R: "1 in = 1 in", X: [1, 0, 0, 1] },
                   type: Pdfrb::Model::Type::Measure)
      expect(rl.class.field(:R).arlington).not_to be_nil
      expect(rl.class.field(:CYX).arlington).not_to be_nil

      geo = doc.add(
        { Type: :Measure, Subtype: :GEO, Bounds: [0, 0, 612, 792],
          GCS: { Type: :GEOGCS, WKT: "GEOGCS[\"WGS 84\"]" },
          PDU: %w[deg m m2] },
        type: Pdfrb::Model::Type::GeospatialMeasure
      )
      expect(geo.geographic_coordinate_system).not_to be_nil
      expect(geo.pdu).to eq(%w[deg m m2])
      expect(geo.bound_count).to eq(4)
      expect(geo.class.field(:GPTS).arlington).not_to be_nil
      expect(geo.class.field(:PCSM).arlington).not_to be_nil
    end
  end
end
