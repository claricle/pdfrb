# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 22 collection type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Collection do
    it "gains Arlington field metadata for all keys" do
      collection = doc.add(
        { Type: :Collection, View: :D, Folders: [], Split: { Direction: :H } },
        type: described_class
      )
      %i[Schema D View Navigator Colors Sort Folders Split Resources].each do |key|
        expect(collection.class.field(key)).not_to be_nil, "missing field #{key}"
      end
      expect(collection.default_view).to eq(:D)
      expect(collection).to be_has_default_view
    end
  end

  describe Pdfrb::Model::Type::CollectionColors do
    it "exposes the five UI color entries" do
      colors = doc.add(
        { Type: :CollectionColors, Background: [0.95],
          CardBorder: [0.1, 0.2, 0.3], PrimaryText: [0, 0, 0] },
        type: described_class
      )
      expect(colors.background).not_to be_nil
      expect(colors.card_border).not_to be_nil
      expect(colors.primary_text).not_to be_nil
      expect(colors.card_background).to be_nil
      expect(colors).to be_gray_background
      expect(colors).not_to be_rgb_background
    end
  end

  describe Pdfrb::Model::Type::CollectionField do
    it "keeps subtype predicates and gains /E metadata" do
      field = doc.add({ Subtype: :Date, N: "Modified", E: true },
                      type: described_class)
      expect(field.name).to eq("Modified")
      expect(field).to be_date_field
      expect(field).not_to be_text_field
      expect(field.class.field(:E)).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::CollectionFolder do
    it "exposes hierarchy links" do
      folder = doc.add(
        { Type: :CollectionFolder, ID: 7, Name: "Reports",
          Child: { ID: 8 }, Desc: "Annual reports" },
        type: described_class
      )
      expect(folder.id).to eq(7)
      expect(folder.name).to eq("Reports")
      expect(folder).to be_root_folder
      expect(folder).to be_has_children
      expect(folder.description).to eq("Annual reports")
    end
  end

  describe Pdfrb::Model::Type::CollectionItem do
    it "gains the wildcard TSV mapping" do
      item = doc.add({ Name: "Q1.pdf", Size: 20_480 },
                     type: described_class)
      expect(item.class.field(:*)).not_to be_nil
      expect(item.value_for("Name")).to eq("Q1.pdf")
      expect(item.keys).to include(:Name, :Size)
    end
  end

  describe Pdfrb::Model::Type::CollectionSchema do
    it "gains the wildcard TSV mapping" do
      schema = doc.add({ Name: { Subtype: :FileName } },
                       type: described_class)
      expect(schema.class.field(:*)).not_to be_nil
      expect(schema.field_count).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::CollectionSort do
    it "gains Arlington metadata and keeps direction flag" do
      sort = doc.add({ S: "Name", A: true }, type: described_class)
      expect(sort.field_name).to eq("Name")
      expect(sort).to be_descending
      expect(sort.class.field(:S).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::CollectionSplit do
    it "exposes direction and position" do
      split = doc.add({ Direction: :V, Position: 0.5 },
                      type: described_class)
      expect(split).to be_vertical
      expect(split).not_to be_horizontal
      expect(split.position).to eq(0.5)
    end
  end

  describe Pdfrb::Model::Type::CollectionSubitem do
    it "exposes display value and folder path" do
      subitem = doc.add({ D: "Final", P: "Reports/2024" },
                        type: described_class)
      expect(subitem.display_value).to eq("Final")
      expect(subitem.parent_folder_path).to eq("Reports/2024")
      expect(subitem).not_to be_numeric_display
    end

    it "types /D as a date when it parses as one" do
      subitem = doc.add({ D: "D:20240101000000-01'00'" },
                        type: described_class)
      expect(subitem.display_value).to be_a(Time)
    end

    it "types /D as a number when numeric" do
      subitem = doc.add({ D: 42 }, type: described_class)
      expect(subitem).to be_numeric_display
    end
  end

  it "wires a full portfolio together" do
    schema = doc.add({ Name: { Subtype: :FileName }, Size: { Subtype: :FileSize } },
                     type: Pdfrb::Model::Type::CollectionSchema)
    folder = doc.add({ Name: "Invoices", ID: 1 },
                     type: Pdfrb::Model::Type::CollectionFolder)
    collection = doc.add(
      { Type: :Collection, Schema: schema, Folders: [folder],
        Colors: doc.add({ Background: [1.0] },
                        type: Pdfrb::Model::Type::CollectionColors) },
      type: Pdfrb::Model::Type::Collection
    )
    doc.catalog[:Collections] = nil
    doc.catalog[:Collection] = Pdfrb::Model::Reference.new(collection.oid, 0)

    expect(collection.schema[:Name][:Subtype]).to eq(:FileName)
    expect(collection.colors[:Background]).not_to be_nil
  end
end
