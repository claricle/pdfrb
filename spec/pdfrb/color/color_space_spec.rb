# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Color::ColorSpace do
  describe "registry" do
    it "registers all device color spaces" do
      expect(described_class.names).to include(:DeviceGray, :DeviceRGB, :DeviceCMYK)
    end

    it "registers CIE-based color spaces" do
      expect(described_class.names).to include(:CalGray, :CalRGB, :Lab, :ICCBased)
    end

    it "registers special color spaces" do
      expect(described_class.names).to include(:Indexed, :Separation, :DeviceN, :Pattern)
    end
  end

  describe Pdfrb::Color::DeviceGray do
    it "serializes to the name /DeviceGray" do
      cs = described_class.new
      expect(cs.to_pdf).to eq(:DeviceGray)
    end
  end

  describe Pdfrb::Color::DeviceRGB do
    it "serializes to the name /DeviceRGB" do
      expect(described_class.new.to_pdf).to eq(:DeviceRGB)
    end
  end

  describe Pdfrb::Color::DeviceCMYK do
    it "serializes to the name /DeviceCMYK" do
      expect(described_class.new.to_pdf).to eq(:DeviceCMYK)
    end
  end

  describe Pdfrb::Color::CalGray do
    it "serializes to [/CalGray << /WhitePoint [...] >>]" do
      cs = described_class.new(white_point: [0.9505, 1.0, 1.089], gamma: 2.2)
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:CalGray)
      params = pdf[1]
      expect(params[:WhitePoint]).to be_a(Pdfrb::Model::PdfArray)
      expect(params[:Gamma]).to eq(2.2)
    end
  end

  describe Pdfrb::Color::CalRGB do
    it "serializes with white point and gamma" do
      cs = described_class.new(white_point: [0.9505, 1.0, 1.089],
                               gamma: [2.2, 2.2, 2.2])
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:CalRGB)
    end
  end

  describe Pdfrb::Color::Lab do
    it "serializes with white point" do
      cs = described_class.new(white_point: [0.9505, 1.0, 1.089])
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:Lab)
    end
  end

  describe Pdfrb::Color::ICCBased do
    it "serializes to [/ICCBased <ref>]" do
      ref = Pdfrb::Model::Reference.new(5, 0)
      cs = described_class.new(ref)
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:ICCBased)
      expect(pdf[1]).to eq(ref)
    end
  end

  describe Pdfrb::Color::Indexed do
    it "serializes to [/Indexed <base> <hival> <lookup>]" do
      cs = described_class.new(base: :DeviceRGB, hival: 3, lookup: "0011223344556")
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:Indexed)
      expect(pdf[1]).to eq(:DeviceRGB)
      expect(pdf[2]).to eq(3)
    end
  end

  describe Pdfrb::Color::Separation do
    it "serializes to [/Separation <name> <alt> <tint>]" do
      cs = described_class.new(
        name: :"PANTONE#20185#20C",
        alternate: :DeviceCMYK,
        tint_transform: Pdfrb::Model::Reference.new(7, 0)
      )
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:Separation)
      expect(pdf[1]).to eq(:"PANTONE#20185#20C")
    end
  end

  describe Pdfrb::Color::DeviceN do
    it "serializes to [/DeviceN [<names>] <alt> <tint>]" do
      cs = described_class.new(
        names: ["Cyan", "Magenta"],
        alternate: :DeviceCMYK,
        tint_transform: Pdfrb::Model::Reference.new(8, 0)
      )
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:DeviceN)
      expect(pdf[1]).to be_a(Pdfrb::Model::PdfArray)
    end
  end

  describe Pdfrb::Color::Pattern do
    it "serializes to /Pattern when no base space" do
      cs = described_class.new
      expect(cs.to_pdf).to eq(:Pattern)
    end

    it "serializes to [/Pattern <base>] when base space given" do
      cs = described_class.new(base: :DeviceRGB)
      pdf = cs.to_pdf
      expect(pdf[0]).to eq(:Pattern)
      expect(pdf[1]).to eq(:DeviceRGB)
    end
  end

  describe "OCP: custom color space" do
    it "allows registering new color spaces" do
      custom = Class.new(Pdfrb::Color::DeviceColorSpace) do
        class << self
          def pdf_name; :MyCustom; end
        end
        register_as
      end

      expect(described_class[:MyCustom]).to be(custom)
    end
  end
end
