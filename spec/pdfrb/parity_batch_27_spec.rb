# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 27 pattern/shading/OC specs" do
  let(:doc) { Pdfrb::Document.new }

  describe "pattern family" do
    it "maps tiling and shading patterns to their TSVs" do
      tilings = Pdfrb::Model::Type::PatternTiling
      shadings = Pdfrb::Model::Type::PatternShading
      registry = Pdfrb::Model::Type.arlington_registry
      expect(registry["PatternType1"]).to eq(tilings)
      expect(registry["PatternType2"]).to eq(shadings)

      tiling = doc.add({ PatternType: 1, PaintType: 1, TilingType: 1,
                         BBox: [0, 0, 100, 100], XStep: 100, YStep: 100,
                         Resources: {} },
                       type: Pdfrb::Model::Type::PatternTiling)
      expect(tiling.class.field(:XStep).arlington).not_to be_nil
      expect(tiling.class.field(:PaintType).arlington).not_to be_nil

      shading = doc.add({ PatternType: 2, Shading: { ShadingType: 2 } },
                        type: Pdfrb::Model::Type::PatternShading)
      expect(shading.class.field(:Shading).arlington).not_to be_nil
      expect(shading.class.field(:ExtGState).arlington).not_to be_nil
    end

    it "adds and looks up patterns via PatternMap" do
      map = doc.add({}, type: Pdfrb::Model::Type::PatternMap)
      map.add(:P1, { PatternType: 1 })
      expect(map[:P1]).not_to be_nil
      expect(map.names).to eq([:P1])
      expect(map.class.field(:*)).not_to be_nil
    end
  end

  describe "shading family" do
    it "registers all seven shading types" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::ShadingType1 => "ShadingType1",
        Pdfrb::Model::Type::ShadingType2 => "ShadingType2",
        Pdfrb::Model::Type::ShadingType3 => "ShadingType3",
        Pdfrb::Model::Type::ShadingType4 => "ShadingType4",
        Pdfrb::Model::Type::ShadingType5 => "ShadingType5",
        Pdfrb::Model::Type::ShadingType6 => "ShadingType6",
        Pdfrb::Model::Type::ShadingType7 => "ShadingType7",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end

    it "exposes axial shading coordinates and extend flags" do
      axial = doc.add(
        { ShadingType: 2, ColorSpace: :DeviceRGB,
          Coords: [0, 0, 100, 100], Function: { FunctionType: 2 },
          Extend: [true, false] },
        type: Pdfrb::Model::Type::ShadingType2
      )
      expect(axial).to be_axial
      expect(axial.x0).to eq(0)
      expect(axial.x1).to eq(100)
      expect(axial).to be_extends_start
      expect(axial).not_to be_extends_end
      expect(axial.class.field(:Coords).arlington).not_to be_nil
    end

    it "exposes radial radii" do
      radial = doc.add({ ShadingType: 3, ColorSpace: :DeviceGray,
                         Coords: [50, 50, 10, 50, 50, 60] },
                       type: Pdfrb::Model::Type::ShadingType3)
      expect(radial).to be_radial
      expect(radial.r0).to eq(10)
      expect(radial.r1).to eq(60)
    end

    it "types 4-7 are stream-backed mesh shadings" do
      mesh = doc.add({ ShadingType: 4, ColorSpace: :DeviceRGB,
                       BitsPerCoordinate: 24, BitsPerComponent: 8,
                       BitsPerFlag: 8, Decode: [0, 1, 0, 1, 0, 1] },
                     type: Pdfrb::Model::Type::ShadingType4)
      expect(mesh).to be_free_form_gouraud
      expect(mesh).to be_a(Pdfrb::Model::Cos::Stream)
      expect(mesh.bits_per_coordinate).to eq(24)

      lattice = doc.add({ ShadingType: 5, VerticesPerRow: 4 },
                        type: Pdfrb::Model::Type::ShadingType5)
      expect(lattice).to be_lattice_gouraud
      expect(lattice.vertices_per_row).to eq(4)

      expect(doc.add({ ShadingType: 6 }, type: Pdfrb::Model::Type::ShadingType6)).to be_coons_patch
      expect(doc.add({ ShadingType: 7 }, type: Pdfrb::Model::Type::ShadingType7)).to be_tensor_patch
    end

    it "adds and looks up shadings via ShadingMap" do
      map = doc.add({}, type: Pdfrb::Model::Type::ShadingMap)
      map.add(:SH1, { ShadingType: 2 })
      expect(map[:SH1]).not_to be_nil
      expect(map.class.field(:*)).not_to be_nil
    end
  end

  describe "optional content family" do
    it "registers all usage dictionaries and the configuration" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::OptionalContentConfiguration => "OptContentConfig",
        Pdfrb::Model::Type::OptContentUsageApplication => "OptContentUsageApplication",
        Pdfrb::Model::Type::OptContentCreatorInfo => "OptContentCreatorInfo",
        Pdfrb::Model::Type::OptContentExport => "OptContentExport",
        Pdfrb::Model::Type::OptContentPrint => "OptContentPrint",
        Pdfrb::Model::Type::OptContentView => "OptContentView",
        Pdfrb::Model::Type::OptContentLanguage => "OptContentLanguage",
        Pdfrb::Model::Type::OptContentPageElement => "OptContentPageElement",
        Pdfrb::Model::Type::OptContentUser => "OptContentUser",
        Pdfrb::Model::Type::OptContentZoom => "OptContentZoom",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end

    it "materializes usage field metadata" do
      print = doc.add({ PrintState: :ON },
                      type: Pdfrb::Model::Type::OptContentPrint)
      expect(print.class.field(:PrintState).arlington).not_to be_nil

      zoom = doc.add({ min: 0, max: 8 },
                     type: Pdfrb::Model::Type::OptContentZoom)
      expect(zoom.min).to eq(0)
      expect(zoom.max).to eq(8)
      expect(zoom.class.field(:min).arlington).not_to be_nil

      user = doc.add({ Name: "Indiv" },
                     type: Pdfrb::Model::Type::OptContentUser)
      expect(user.name).to eq("Indiv")

      config = doc.add({ Name: "Default" },
                       type: Pdfrb::Model::Type::OptionalContentConfiguration)
      expect(config.class.field(:BaseState).arlington).not_to be_nil
      expect(config.class.field(:ON).arlington).not_to be_nil
    end
  end
end
