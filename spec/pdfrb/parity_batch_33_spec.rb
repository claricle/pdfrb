# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 33 xobject/font/softmask types" do
  let(:doc) { Pdfrb::Document.new }

  it "registers all new classes under their TSVs" do
    klasses = {
      Pdfrb::Model::Type::XObjectFormPS => "XObjectFormPS",
      Pdfrb::Model::Type::XObjectFormPSpassthrough => "XObjectFormPSpassthrough",
      Pdfrb::Model::Type::XObjectFormPrinterMark => "XObjectFormPrinterMark",
      Pdfrb::Model::Type::XObjectFormTrapNet => "XObjectFormTrapNet",
      Pdfrb::Model::Type::XObjectMap => "XObjectMap",
      Pdfrb::Model::Type::XObjectImageMask => "XObjectImageMask",
      Pdfrb::Model::Type::XObjectImageSoftMask => "XObjectImageSoftMask",
      Pdfrb::Model::Type::FontFile3Type1 => "FontFile3Type1",
      Pdfrb::Model::Type::FontFile3CIDType0 => "FontFile3CIDType0",
      Pdfrb::Model::Type::FontFile3OpenType => "FontFile3OpenType",
      Pdfrb::Model::Type::FontDescriptorTrueType => "FontDescriptorTrueType",
      Pdfrb::Model::Type::FontDescriptorType3 => "FontDescriptorType3",
      Pdfrb::Model::Type::SoftMaskAlpha => "SoftMaskAlpha",
      Pdfrb::Model::Type::SoftMaskLuminosity => "SoftMaskLuminosity",
      Pdfrb::Model::Type::GraphicsStateParameterMap => "GraphicsStateParameterMap",
      Pdfrb::Model::Type::GroupAttributes => "GroupAttributes",
    }
    registry = Pdfrb::Model::Type.arlington_registry
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  describe "XObject form variants" do
    it "exposes PostScript XObject keys" do
      ps = doc.add({ Type: :XObject, Subtype: :PS, Level1: true },
                   type: Pdfrb::Model::Type::XObjectFormPS)
      expect(ps.level1).to be true

      passthrough = doc.add({ Type: :XObject, Subtype: :PS, Subtype2: :PS,
                              PS: "..." },
                            type: Pdfrb::Model::Type::XObjectFormPSpassthrough)
      expect(passthrough.postscript).not_to be_nil
      expect(passthrough.class.field(:Subtype2).arlington).not_to be_nil
    end

    it "exposes printer-mark and trap-net form keys" do
      mark = doc.add({ Type: :XObject, Subtype: :Form,
                       MarkStyle: :Single, Colorants: {} },
                     type: Pdfrb::Model::Type::XObjectFormPrinterMark)
      expect(mark.mark_style).to eq(:Single)
      expect(mark.class.field(:Colorants).arlington).not_to be_nil

      trap = doc.add({ Type: :XObject, Subtype: :Form, PCM: :DeviceCMYK,
                       TrapRegions: [0], TrapStyles: "xy" },
                     type: Pdfrb::Model::Type::XObjectFormTrapNet)
      expect(trap.pcm).to eq(:DeviceCMYK)
      expect(trap.trap_styles).to eq("xy")
      expect(trap.class.field(:SeparationColorNames).arlington).not_to be_nil
    end
  end

  describe "image variants" do
    it "classifies stencil decode inversion" do
      mask = doc.add({ Type: :XObject, Subtype: :Image, Width: 8,
                       Height: 8, ImageMask: true, Decode: [1, 0] },
                     type: Pdfrb::Model::Type::XObjectImageMask)
      expect(mask).to be_inverted

      normal = doc.add({ Type: :XObject, Subtype: :Image, Width: 8,
                         Height: 8, ImageMask: true, Decode: [0, 1] },
                       type: Pdfrb::Model::Type::XObjectImageMask)
      expect(normal).not_to be_inverted
    end

    it "exposes soft-mask image matte" do
      smask = doc.add({ Type: :XObject, Subtype: :Image, Width: 4,
                        Height: 4, ColorSpace: :DeviceGray,
                        Matte: [0.1, 0.2, 0.3] },
                      type: Pdfrb::Model::Type::XObjectImageSoftMask)
      expect(smask.matte).to eq([0.1, 0.2, 0.3])
      expect(smask.class.field(:Matte).arlington).not_to be_nil
    end

    it "adds and looks up XObjects via XObjectMap" do
      map = doc.add({}, type: Pdfrb::Model::Type::XObjectMap)
      map.add(:X1, { Type: :XObject, Subtype: :Image })
      expect(map[:X1]).not_to be_nil
      expect(map.names).to eq([:X1])
      expect(map.class.field(:*)).not_to be_nil
    end
  end

  describe "font file and descriptor variants" do
    it "maps the FontFile3 subtype split" do
      t1c = doc.add({ Subtype: :Type1C }, type: Pdfrb::Model::Type::FontFile3Type1)
      expect(t1c.class.field(:Subtype).arlington).not_to be_nil
      expect(t1c).to be_a(Pdfrb::Model::Type::FontFile3)

      cid = doc.add({ Subtype: :CIDFontType0C },
                    type: Pdfrb::Model::Type::FontFile3CIDType0)
      expect(cid.class.field(:Length1).arlington).not_to be_nil

      otf = doc.add({ Subtype: :OpenType },
                    type: Pdfrb::Model::Type::FontFile3OpenType)
      expect(otf.class.field(:Metadata).arlington).not_to be_nil
    end

    it "maps font descriptor variants" do
      tt = doc.add({ FontName: :Helvetica, Flags: 32,
                     FontFile2: { Length: 42 } },
                   type: Pdfrb::Model::Type::FontDescriptorTrueType)
      expect(tt.font_file2).not_to be_nil
      expect(tt.class.field(:FontFile3).arlington).not_to be_nil

      t3 = doc.add({ FontName: :F3, Flags: 4 },
                   type: Pdfrb::Model::Type::FontDescriptorType3)
      expect(t3.class.field(:FontFile2)).to be_nil
      expect(t3.class.field(:FontName).arlington).not_to be_nil
    end
  end

  describe "soft masks and groups" do
    it "classifies alpha vs luminosity" do
      alpha = doc.add({ Type: :Mask, S: :Alpha, G: { Group: true } },
                      type: Pdfrb::Model::Type::SoftMaskAlpha)
      expect(alpha).to be_alpha
      expect(alpha).not_to be_luminosity
      expect(alpha.group).not_to be_nil
      expect(alpha.class.field(:TR).arlington).not_to be_nil

      lumi = doc.add({ Type: :Mask, S: :Luminosity, BC: [0.5] },
                     type: Pdfrb::Model::Type::SoftMaskLuminosity)
      expect(lumi).to be_luminosity
      expect(lumi.backdrop_color).to eq([0.5])
    end

    it "maps ExtGState resources and transparency groups" do
      gs = doc.add({}, type: Pdfrb::Model::Type::GraphicsStateParameterMap)
      gs.add(:GS1, { CA: 0.5 })
      expect(gs[:GS1]).not_to be_nil
      expect(gs.class.field(:*)).not_to be_nil

      group = doc.add({ Type: :Group, S: :Transparency, I: true, K: false },
                      type: Pdfrb::Model::Type::GroupAttributes)
      expect(group).to be_transparency_group
      expect(group).to be_isolated
      expect(group).not_to be_knockout
    end
  end
end
