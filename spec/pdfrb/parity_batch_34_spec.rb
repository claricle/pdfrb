# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 34 geospatial/OPI/struct types" do
  let(:doc) { Pdfrb::Document.new }

  it "registers all new classes under their TSVs" do
    klasses = {
      Pdfrb::Model::Type::GeographicCoordinateSystem => "GeographicCoordinateSystem",
      Pdfrb::Model::Type::ProjectedCoordinateSystem => "ProjectedCoordinateSystem",
      Pdfrb::Model::Type::PointData => "PointData",
      Pdfrb::Model::Type::Projection => "Projection",
      Pdfrb::Model::Type::NumberFormat => "NumberFormat",
      Pdfrb::Model::Type::OPIVersion13Dict => "OPIVersion13Dict",
      Pdfrb::Model::Type::OPIVersion20Dict => "OPIVersion20Dict",
      Pdfrb::Model::Type::RichMediaParams => "RichMediaParams",
      Pdfrb::Model::Type::RichMediaHeight => "RichMediaHeight",
      Pdfrb::Model::Type::RichMediaWidth => "RichMediaWidth",
      Pdfrb::Model::Type::RichMediaPosition => "RichMediaPosition",
      Pdfrb::Model::Type::RoleMap => "RoleMap",
      Pdfrb::Model::Type::RoleMapNS => "RoleMapNS",
      Pdfrb::Model::Type::StyleDict => "StyleDict",
      Pdfrb::Model::Type::ClassMap => "ClassMap",
      Pdfrb::Model::Type::StructureReference => "Reference",
      Pdfrb::Model::Type::StructureAttributes => "StructureAttributesDict",
    }
    registry = Pdfrb::Model::Type.arlington_registry
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  describe "geospatial family" do
    it "identifies coordinate systems by EPSG or WKT" do
      gcs = doc.add({ Type: :GEOGCS, EPSG: 4326 },
                    type: Pdfrb::Model::Type::GeographicCoordinateSystem)
      expect(gcs.epsg).to eq(4326)
      expect(gcs).to be_epsg_defined

      pcs = doc.add({ Type: :PROJCS, WKT: "PROJCS[\"WGS 84 / UTM 33N\"]" },
                    type: Pdfrb::Model::Type::ProjectedCoordinateSystem)
      expect(pcs.wkt).to start_with("PROJCS")
    end

    it "exposes point-data pairs" do
      pt = doc.add({ Type: :PtData, Subtype: :LatLon,
                     Names: ["top-left"], XPTS: [10.0, 20.0] },
                   type: Pdfrb::Model::Type::PointData)
      expect(pt.names).to eq(["top-left"])
      expect(pt.xpts).to eq([10.0, 20.0])
      expect(pt.class.field(:XPTS).arlington).not_to be_nil
    end

    it "exposes 3D projection parameters" do
      proj = doc.add({ Subtype: :OR, CS: :DeviceRGB, F: 1.5, PS: 2.0 },
                     type: Pdfrb::Model::Type::Projection)
      expect(proj.color_space).to eq(:DeviceRGB)
      expect(proj.field_of_view).to be_nil
    end

    it "exposes number-format settings" do
      nf = doc.add({ U: "cm", C: 0.352778, F: 2, PS: "comma" },
                   type: Pdfrb::Model::Type::NumberFormat)
      expect(nf.unit).to eq("cm")
      expect(nf.fractional_digits).to eq(2)
      expect(nf.class.field(:RT).arlington).not_to be_nil
    end
  end

  describe "OPI dictionaries" do
    it "exposes v1.3 proxy keys" do
      opi = doc.add({ Version: "1.3", ID: "0123", Size: [800, 600],
                      ColorType: 1, Resolution: [300, 300] },
                    type: Pdfrb::Model::Type::OPIVersion13Dict)
      expect(opi.id).to eq("0123")
      expect(opi.resolution).to eq([300, 300])
      expect(opi.class.field(:GrayMap).arlington).not_to be_nil
    end

    it "exposes v2.0 proxy keys" do
      opi = doc.add({ Version: "2.0", Transparency: true },
                    type: Pdfrb::Model::Type::OPIVersion20Dict)
      expect(opi.transparency).to be true
    end
  end

  describe "rich media leftovers" do
    it "exposes params and sizing" do
      params = doc.add({ FlashVars: "autoplay=1", Binding: :Foreground },
                       type: Pdfrb::Model::Type::RichMediaParams)
      expect(params.flash_vars).to eq("autoplay=1")

      height = doc.add({ Default: 50, Max: 100, Min: 10 },
                       type: Pdfrb::Model::Type::RichMediaHeight)
      expect(height.default).to eq(50)

      position = doc.add({ HAlign: :near, VAlign: :near, HOffset: 5 },
                         type: Pdfrb::Model::Type::RichMediaPosition)
      expect(position.h_align).to eq(:near)
    end
  end

  describe "structure tree family" do
    it "looks up custom roles and classes" do
      role_map = doc.add({ Chapter: :H1, Caption: :Caption },
                         type: Pdfrb::Model::Type::RoleMap)
      expect(role_map[:Chapter]).to eq(:H1)
      expect(role_map.custom_names).to include(:Chapter)
      expect(role_map.class.field(:*)).not_to be_nil

      class_map = doc.add({ layout: { O: { Placement: :Block } } },
                          type: Pdfrb::Model::Type::ClassMap)
      expect(class_map.class_names).to eq([:layout])

      ns_map = doc.add({ "http://example.org/ns" => {} },
                       type: Pdfrb::Model::Type::RoleMapNS)
      expect(ns_map[:"http://example.org/ns"]).not_to be_nil
    end

    it "exposes style and attribute-owner metadata" do
      style = doc.add({ Panose: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
                      type: Pdfrb::Model::Type::StyleDict)
      expect(style.panose.size).to eq(10)

      attrs = doc.add({ O: { Layout: {} }, NS: "http://example.org" },
                      type: Pdfrb::Model::Type::StructureAttributes)
      expect(attrs.class.field(:Placement).arlington).not_to be_nil
      expect(attrs.class.field(:TextAlign).arlington).not_to be_nil
    end

    it "resolves reference kids" do
      ref = doc.add({ F: "other.pdf", Page: 2, ID: ["a", "b"] },
                    type: Pdfrb::Model::Type::StructureReference)
      expect(ref.file).to eq("other.pdf")
      expect(ref.ids).to eq(["a", "b"])
    end
  end
end
