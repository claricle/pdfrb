# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 31 DecodeParms + arrays" do
  let(:doc) { Pdfrb::Document.new }

  describe "filter DecodeParms family" do
    it "registers all six DecodeParms classes" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::FlateDecodeParms => "FilterFlateDecode",
        Pdfrb::Model::Type::LZWDecodeParms => "FilterLZWDecode",
        Pdfrb::Model::Type::DCTDecodeParms => "FilterDCTDecode",
        Pdfrb::Model::Type::CCITTFaxDecodeParms => "FilterCCITTFaxDecode",
        Pdfrb::Model::Type::JBIG2DecodeParms => "FilterJBIG2Decode",
        Pdfrb::Model::Type::CryptDecodeParms => "FilterCrypt",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end

    it "exposes predictor settings with defaults" do
      parms = doc.add({ Predictor: 12, Colors: 3, BitsPerComponent: 8,
                        Columns: 256 },
                      type: Pdfrb::Model::Type::FlateDecodeParms)
      expect(parms.predictor).to eq(12)
      expect(parms).to be_png_predictor
      expect(parms).not_to be_tiff_predictor
      expect(parms.colors).to eq(3)
      expect(parms.columns).to eq(256)

      default = doc.add({}, type: Pdfrb::Model::Type::FlateDecodeParms)
      expect(default.predictor).to eq(1)
      expect(default.bits_per_component).to eq(8)
    end

    it "adds EarlyChange to LZW" do
      parms = doc.add({ Predictor: 2, EarlyChange: 0 },
                      type: Pdfrb::Model::Type::LZWDecodeParms)
      expect(parms.early_change).to eq(0)
      expect(parms).to be_tiff_predictor
    end

    it "classifies DCT color transform" do
      cmyk = doc.add({ ColorTransform: 0 },
                     type: Pdfrb::Model::Type::DCTDecodeParms)
      expect(cmyk).to be_cmyk_input
      rgb = doc.add({}, type: Pdfrb::Model::Type::DCTDecodeParms)
      expect(rgb).not_to be_cmyk_input
    end

    it "classifies CCITT groups" do
      g4 = doc.add({ K: -1, Columns: 1728 },
                   type: Pdfrb::Model::Type::CCITTFaxDecodeParms)
      expect(g4).to be_group4
      expect(g4.columns).to eq(1728)

      g3_1d = doc.add({ K: 0 },
                      type: Pdfrb::Model::Type::CCITTFaxDecodeParms)
      expect(g3_1d).to be_group3_1d

      g3_2d = doc.add({ K: 4 },
                      type: Pdfrb::Model::Type::CCITTFaxDecodeParms)
      expect(g3_2d).to be_group3_2d
    end

    it "exposes JBIG2 globals and crypt name" do
      jbig = doc.add({ JBIG2Globals: { Type: :XObject } },
                     type: Pdfrb::Model::Type::JBIG2DecodeParms)
      expect(jbig.jbig2_globals).not_to be_nil
      expect(jbig.class.field(:JBIG2Globals).arlington).not_to be_nil

      crypt = doc.add({}, type: Pdfrb::Model::Type::CryptDecodeParms)
      expect(crypt.name).to eq(:Identity)
    end
  end

  describe "simple array types" do
    it "exposes gamma and whitepoint components" do
      gamma = doc.add([1.8, 1.8, 1.8], type: Pdfrb::Model::Type::GammaArray)
      expect(gamma.r).to eq(1.8)
      expect(gamma.b).to eq(1.8)

      white = doc.add([0.95, 1.0, 1.09], type: Pdfrb::Model::Type::WhitepointArray)
      expect(white.y).to eq(1.0)
    end

    it "exposes trailer ID halves" do
      ids = doc.add(["\x01\x02".b, "\x03\x04".b],
                    type: Pdfrb::Model::Type::TrailerIDArray)
      expect(ids.id1.bytesize).to eq(2)
      expect(ids.id2.bytesize).to eq(2)
    end

    it "parses visibility expressions" do
      expr = doc.add([:And, [:OC1], [:Or, [:OC2], [:OC3]]],
                     type: Pdfrb::Model::Type::VisibilityExpressionArray)
      expect(expr).to be_and
      expect(expr).not_to be_or
      expect(expr.operands.size).to eq(2)
    end

    it "walks related-files pairs" do
      related = doc.add(["a.pdf", { Type: :EmbeddedFile }],
                        type: Pdfrb::Model::Type::RelatedFilesArray)
      pairs = related.each_pair.to_a
      expect(pairs.size).to eq(1)
      expect(pairs[0][0]).to eq("a.pdf")
    end

    it "registers the five UR param arrays and universals" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::URTransformParamArray => "URTransformParamDocumentArray",
        Pdfrb::Model::Type::URTransformParamAnnotsArray => "URTransformParamAnnotsArray",
        Pdfrb::Model::Type::URTransformParamEFArray => "URTransformParamEFArray",
        Pdfrb::Model::Type::URTransformParamFormArray => "URTransformParamFormArray",
        Pdfrb::Model::Type::URTransformParamSignatureArray => "URTransformParamSignatureArray",
        Pdfrb::Model::Type::UniversalArray => "_UniversalArray",
        Pdfrb::Model::Type::UniversalDictionary => "_UniversalDictionary",
        Pdfrb::Model::Type::RichMediaCommandArray => "RichMediaCommandArray",
        Pdfrb::Model::Type::OOAdditionalStmsArray => "OOAdditionalStmsArray",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end
  end
end
