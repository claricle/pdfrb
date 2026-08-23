# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 24 color-space specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::ColorSpace do
    it "distinguishes device and family forms" do
      cs = described_class.new([:DeviceRGB])
      expect(cs).to be_device
      expect(cs).not_to be_based
      expect(cs.family).to eq(:DeviceRGB)
    end
  end

  describe Pdfrb::Model::Type::CalGrayColorSpace do
    it "exposes the dict and defaults gamma" do
      cs = doc.add([:CalGray, { WhitePoint: [0.95, 1.0, 1.09] }],
                   type: described_class)
      expect(cs.cal_gray_dict[:WhitePoint]).to eq([0.95, 1.0, 1.09])
      expect(cs.gamma).to eq(1.0)
    end
  end

  describe Pdfrb::Model::Type::CalRGBColorSpace do
    it "exposes gamma from the dict" do
      cs = doc.add([:CalRGB, { WhitePoint: [0.95, 1.0, 1.09], Gamma: [2.2, 2.2, 2.2] }],
                   type: described_class)
      expect(cs.gamma).to eq([2.2, 2.2, 2.2])
    end
  end

  describe Pdfrb::Model::Type::LabColorSpace do
    it "exposes the range" do
      cs = doc.add([:Lab, { WhitePoint: [0.95, 1.0, 1.09], Range: [-128, 127, -128, 127] }],
                   type: described_class)
      expect(cs.range).to eq([-128, 127, -128, 127])
    end
  end

  describe "device color spaces" do
    it "report component counts" do
      expect(doc.add([:DeviceGray], type: Pdfrb::Model::Type::DeviceGrayColorSpace).components).to eq(1)
      expect(doc.add([:DeviceRGB], type: Pdfrb::Model::Type::DeviceRGBColorSpace).components).to eq(3)
      expect(doc.add([:DeviceCMYK], type: Pdfrb::Model::Type::DeviceCMYKColorSpace).components).to eq(4)
    end
  end

  describe Pdfrb::Model::Type::ICCBasedColorSpaceArray do
    it "reads component count and alternate from the profile" do
      cs = doc.add([:ICCBased, { N: 3, Alternate: :DeviceRGB }],
                   type: described_class)
      expect(cs.components).to eq(3)
      expect(cs.alternate_space).to eq(:DeviceRGB)
    end
  end

  describe Pdfrb::Model::Type::IndexedColorSpace do
    it "exposes base, hival, and lookup" do
      lookup = (+"\x00\x40\x80\xFF").b
      cs = doc.add([:Indexed, :DeviceRGB, 3, lookup], type: described_class)
      expect(cs.base).to eq(:DeviceRGB)
      expect(cs.hival).to eq(3)
      expect(cs.lookup_length).to eq(4)
      expect(cs.components).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::SeparationColorSpace do
    it "exposes colorant, alternate space, and tint transform" do
      cs = doc.add([:Separation, :SpotRed, :DeviceRGB, { FunctionType: 2 }],
                   type: described_class)
      expect(cs.colorant_name).to eq(:SpotRed)
      expect(cs.alternate_space).to eq(:DeviceRGB)
      expect(cs.tint_transform[:FunctionType]).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::DeviceNColorSpace do
    it "exposes colorant list and attributes" do
      cs = doc.add([:DeviceN, %i[Cyan Gold], :DeviceCMYK, { FunctionType: 2 },
                    { Subtype: :NChannel, Colorants: {} }],
                   type: described_class)
      expect(cs.colorant_names).to eq(%i[Cyan Gold])
      expect(cs.components).to eq(2)
      expect(cs.attributes[:Subtype]).to eq(:NChannel)
    end
  end

  describe Pdfrb::Model::Type::PatternColorSpace do
    it "detects uncolored pattern families" do
      colored = doc.add([:Pattern], type: described_class)
      expect(colored).not_to be_uncolored
      uncolored = doc.add([:Pattern, :DeviceRGB], type: described_class)
      expect(uncolored).to be_uncolored
    end
  end

  describe Pdfrb::Model::Type::BlackpointArray do
    it "exposes XYZ coordinates" do
      bp = doc.add([0.0, 0.0, 0.0], type: described_class)
      expect(bp.x).to eq(0.0)
      expect(bp.y).to eq(0.0)
      expect(bp.z).to eq(0.0)
    end
  end

  describe Pdfrb::Model::Type::ColorSpaceMap do
    it "adds and looks up named spaces with defaults" do
      map = doc.add({ DefaultGray: :DeviceGray }, type: described_class)
      map.add(:CS1, [:CalRGB, { WhitePoint: [0.95, 1.0, 1.09] }])
      expect(map[:CS1]).not_to be_nil
      expect(map.default_gray).to eq(:DeviceGray)
      expect(map.names).to include(:CS1, :DefaultGray)
    end
  end

  describe Pdfrb::Model::Type::ColorantsDict do
    it "enumerates colorant names" do
      dict = doc.add({ Gold: [:Separation, :Gold, :DeviceCMYK, { FunctionType: 2 }] },
                     type: described_class)
      expect(dict[:Gold]).not_to be_nil
      expect(dict.colorant_names).to eq([:Gold])
    end
  end

  describe Pdfrb::Model::Type::BoxStyle do
    it "exposes color, width, style, dash with defaults" do
      style = doc.add({ C: [1, 0, 0], W: 2.5, S: :D, D: [3, 2] },
                      type: described_class)
      expect(style.color).to eq([1, 0, 0])
      expect(style.width).to eq(2.5)
      expect(style).to be_dashed
      expect(style.dash).to eq([3, 2])
    end
  end

  describe "existing dict mappings" do
    it "maps CalGray/CalRGB/Lab to their dict TSVs" do
      cg = doc.add({ WhitePoint: [0.95, 1.0, 1.09] },
                   type: Pdfrb::Model::Type::CalGray)
      expect(cg.class.field(:WhitePoint).arlington).not_to be_nil
      expect(cg.class.field(:Gamma).arlington).not_to be_nil

      lab = doc.add({ WhitePoint: [0.95, 1.0, 1.09], Range: [-100, 100, -100, 100] },
                    type: Pdfrb::Model::Type::Lab)
      expect(lab.class.field(:Range).arlington).not_to be_nil
    end

    it "maps LabRangeArray and BoxColorInfo and PageLabel" do
      lr = Pdfrb::Model::Type::LabRangeArray
      expect(lr.arlington_definition).not_to be_nil
      expect(lr.element_field(0)).not_to be_nil

      bci = doc.add({ CropBox: { C: [0, 0, 0] } },
                    type: Pdfrb::Model::Type::BoxColorInfo)
      expect(bci.class.field(:CropBox).arlington).not_to be_nil

      pl = doc.add({ S: :D, St: 3 }, type: Pdfrb::Model::Type::PageLabel)
      expect(pl.class.field(:St).arlington).not_to be_nil
    end
  end
end
