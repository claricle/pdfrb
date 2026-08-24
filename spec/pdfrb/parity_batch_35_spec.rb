# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 35 signature/extension types" do
  let(:doc) { Pdfrb::Document.new }

  it "registers all new classes under their TSVs" do
    klasses = {
      Pdfrb::Model::Type::CertSeedValue => "CertSeedValue",
      Pdfrb::Model::Type::SubjectDN => "SubjectDN",
      Pdfrb::Model::Type::DocTimeStamp => "DocTimeStamp",
      Pdfrb::Model::Type::TimeStampDict => "TimeStampDict",
      Pdfrb::Model::Type::AuthCode => "AuthCode",
      Pdfrb::Model::Type::LegalAttestation => "LegalAttestation",
      Pdfrb::Model::Type::VRIMap => "VRIMap",
      Pdfrb::Model::Type::AFEmbeddedFileParameter => "AFEmbeddedFileParameter",
      Pdfrb::Model::Type::AFFileSpecEF => "AFFileSpecEF",
      Pdfrb::Model::Type::Target => "Target",
      Pdfrb::Model::Type::TargetEmbedded => "TargetEmbedded",
      Pdfrb::Model::Type::DevExtensions => "DevExtensions",
      Pdfrb::Model::Type::GTSmDevExtensions => "GTSm_DevExtensions",
      Pdfrb::Model::Type::ISODevExtensions => "ISO_DevExtensions",
      Pdfrb::Model::Type::Extensions => "Extensions",
      Pdfrb::Model::Type::GTSProcStepsGroup => "GTS_ProcStepsGroup",
      Pdfrb::Model::Type::AppleSupplementalText => "AAPL_ST",
      Pdfrb::Model::Type::SignatureBuildPropDict => "SignatureBuildPropDict",
    }
    registry = Pdfrb::Model::Type.arlington_registry
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  describe "seed values and timestamps" do
    it "constrains the signing certificate" do
      cert = doc.add(
        { Ff: 1, SubjectDN: { CN: "Signer" }, KeyUsage: 3,
          URL: "https://ca.example.org" },
        type: Pdfrb::Model::Type::CertSeedValue
      )
      expect(cert.key_usage).to eq(3)
      expect(cert.class.field(:SignaturePolicyOID).arlington).not_to be_nil

      dn = doc.add({ CN: "Signer", O: "Example" },
                   type: Pdfrb::Model::Type::SubjectDN)
      expect(dn[:CN]).to eq("Signer")
      expect(dn.components).to include(:O)
    end

    it "exposes doc timestamp and TSA URL dictionaries" do
      ts = doc.add({ Type: :DocTimeStamp, Filter: "Adobe.PPKLite",
                     SubFilter: "ETSI.RFC3161", ByteRange: [0, 1, 2, 3] },
                   type: Pdfrb::Model::Type::DocTimeStamp)
      expect(ts.subfilter).to eq("ETSI.RFC3161")
      expect(ts.class.field(:Prop_Build).arlington).not_to be_nil

      tsa = doc.add({ URL: "https://tsa.example.org", Ff: 1 },
                    type: Pdfrb::Model::Type::TimeStampDict)
      expect(tsa.url).to eq("https://tsa.example.org")
    end
  end

  describe "legal attestation and VRI" do
    it "exposes attestation flags and VRI entries" do
      legal = doc.add({ JavaScriptActions: true, NonEmbeddedFonts: true },
                      type: Pdfrb::Model::Type::LegalAttestation)
      expect(legal.javascript_actions).to be true
      expect(legal.class.field(:OptionalContent).arlington).not_to be_nil

      vri = doc.add({ "2BC0CA1F" => { Cert: [] } },
                    type: Pdfrb::Model::Type::VRIMap)
      expect(vri[:"2BC0CA1F"]).not_to be_nil
      expect(vri.class.field(:*)).not_to be_nil
    end
  end

  describe "associated files" do
    it "exposes AF parameters and EF maps" do
      params = doc.add({ Size: 4096, CheckSum: "abc" },
                       type: Pdfrb::Model::Type::AFEmbeddedFileParameter)
      expect(params.size).to eq(4096)
      expect(params.class.field(:Mac).arlington).not_to be_nil

      ef = doc.add({ F: { Type: :EmbeddedFile } },
                   type: Pdfrb::Model::Type::AFFileSpecEF)
      expect(ef.f).not_to be_nil
      expect(ef.class.field(:UF).arlington).not_to be_nil
    end
  end

  describe "GoToE targets" do
    it "classifies target relations" do
      parent = doc.add({ R: :P, P: 3 },
                       type: Pdfrb::Model::Type::Target)
      expect(parent).to be_parent_relation
      expect(parent).not_to be_child_relation
      expect(parent.page).to eq(3)

      child = doc.add({ R: :C, T: { R: :P } },
                      type: Pdfrb::Model::Type::TargetEmbedded)
      expect(child).to be_child_relation
      expect(child.nested_target).not_to be_nil
      expect(child).to be_a(Pdfrb::Model::Type::Target)
    end
  end

  describe "developer extensions" do
    it "exposes base version, level, and URL" do
      dev = doc.add({ BaseVersion: 1.7, ExtensionLevel: 3,
                      URL: "https://developer.example.org" },
                    type: Pdfrb::Model::Type::DevExtensions)
      expect(dev.base_version).to eq(1.7)
      expect(dev.extension_level).to eq(3)
      expect(dev.class.field(:ExtensionRevision).arlington).not_to be_nil
    end

    it "maps the container and vendor variants" do
      ext = doc.add({ ADBE: { ExtensionLevel: 3 } },
                    type: Pdfrb::Model::Type::Extensions)
      expect(ext[:ADBE]).not_to be_nil
      expect(ext.developers).to eq([:ADBE])
      expect(ext.class.field(:ISO_).arlington).not_to be_nil

      expect(Pdfrb::Model::Type::GTSmDevExtensions).to be < Pdfrb::Model::Type::DevExtensions
      expect(Pdfrb::Model::Type::ISODevExtensions).to be < Pdfrb::Model::Type::DevExtensions
    end
  end

  describe "vendor one-offs" do
    it "exposes GTS procedural steps and Apple supplemental text" do
      steps = doc.add({ GTS_ProcStepsGroup: :Coating,
                        GTS_ProcStepsType: :Varnish },
                      type: Pdfrb::Model::Type::GTSProcStepsGroup)
      expect(steps.group).to eq(:Coating)

      st = doc.add({ Type: :AAPL_ST, Offset: [1, 2], Radius: 3 },
                   type: Pdfrb::Model::Type::AppleSupplementalText)
      expect(st.radius).to eq(3)
      expect(st.class.field(:ColorSpace).arlington).not_to be_nil
    end
  end
end
