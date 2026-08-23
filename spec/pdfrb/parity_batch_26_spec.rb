# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 26 font/signature mappings" do
  let(:doc) { Pdfrb::Document.new }

  describe "font family" do
    it "registers all font classes under their TSVs" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::FontFile => "FontFile",
        Pdfrb::Model::Type::FontFile2 => "FontFile2",
        Pdfrb::Model::Type::FontCIDType0 => "FontCIDType0",
        Pdfrb::Model::Type::FontCIDType2 => "FontCIDType2",
        Pdfrb::Model::Type::FontDescriptorCIDType0 => "FontDescriptorCIDType0",
        Pdfrb::Model::Type::FontDescriptorCIDType2 => "FontDescriptorCIDType2",
        Pdfrb::Model::Type::FontMultipleMaster => "FontMultipleMaster",
        Pdfrb::Model::Type::CharProcMap => "CharProcMap",
        Pdfrb::Model::Type::FontEncoding => "Encoding",
        Pdfrb::Model::Type::ToUnicodeCMapStream => "ToUnicodeCMapStream",
        Pdfrb::Model::Type::CIDFontDescriptorMetrics => "CIDFontDescriptorMetrics",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end

    it "materializes stream-length and CIDSystemInfo metadata" do
      ff = doc.add({ Length1: 1234, Length2: 0 }, type: Pdfrb::Model::Type::FontFile)
      expect(ff.class.field(:Length1).arlington).not_to be_nil
      expect(ff.class.field(:Length3).arlington).not_to be_nil

      cid = doc.add({ CIDSystemInfo: { Registry: "Adobe" } },
                    type: Pdfrb::Model::Type::FontCIDType0)
      expect(cid.class.field(:CIDSystemInfo).arlington).not_to be_nil
      expect(cid.class.field(:CIDToGIDMap).arlington).not_to be_nil
    end

    it "maps FontEncoding to the Encoding TSV" do
      enc = doc.add({ BaseEncoding: :WinAnsiEncoding,
                      Differences: [23, :adieresis] },
                    type: Pdfrb::Model::Type::FontEncoding)
      expect(enc.class.field(:BaseEncoding).arlington).not_to be_nil
      expect(enc.class.field(:Differences).arlington).not_to be_nil
    end
  end

  describe "signature family" do
    it "registers all signature classes under their TSVs" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::Signature => "Signature",
        Pdfrb::Model::Type::SigFieldLock => "SigFieldLock",
        Pdfrb::Model::Type::SigFieldSeedValue => "SigFieldSeedValue",
        Pdfrb::Model::Type::SignatureBuildDataDict => "SignatureBuildDataDict",
        Pdfrb::Model::Type::SignatureBuildDataAppDict => "SignatureBuildDataAppDict",
        Pdfrb::Model::Type::SignatureBuildDataSigQDict => "SignatureBuildDataSigQDict",
        Pdfrb::Model::Type::SignatureReferenceDocMDP => "SignatureReferenceDocMDP",
        Pdfrb::Model::Type::SignatureReferenceIdentity => "SignatureReferenceIdentity",
        Pdfrb::Model::Type::SignatureReferenceUR => "SignatureReferenceUR",
        Pdfrb::Model::Type::SignatureReferenceFieldMDP => "SignatureReferenceFieldMDP",
        Pdfrb::Model::Type::DocMDPTransformParameters => "DocMDPTransformParameters",
        Pdfrb::Model::Type::FieldMDPTransformParameters => "FieldMDPTransformParameters",
        Pdfrb::Model::Type::MDPDict => "MDPDict",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end

    it "materializes seed-value and lock metadata" do
      sv = doc.add({ Filter: "Adobe.PPKLite", Reason: "Approval" },
                   type: Pdfrb::Model::Type::SigFieldSeedValue)
      expect(sv.class.field(:Reasons).arlington).not_to be_nil
      expect(sv.class.field(:LegalAttestation).arlington).not_to be_nil

      lock = doc.add({ Action: :All }, type: Pdfrb::Model::Type::SigFieldLock)
      expect(lock.class.field(:Action).arlington).not_to be_nil
      expect(lock.class.field(:Fields).arlington).not_to be_nil
    end

    it "keeps byte_range validation working with wrapped arrays" do
      sig = doc.add({ Type: :Sig, Filter: "Adobe.PPKLite",
                      ByteRange: [0, 100, 200, 50] },
                    type: Pdfrb::Model::Type::Signature)
      expect(sig).to be_has_byte_range
    end
  end
end
