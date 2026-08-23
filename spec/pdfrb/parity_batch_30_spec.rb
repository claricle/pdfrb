# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 30 requirements handlers" do
  let(:doc) { Pdfrb::Document.new }

  it "registers all 28 handler classes under their TSVs" do
    klasses = %w[
      Requirements3DMarkup RequirementsAcroFormInteract RequirementsAction
      RequirementsAttachment RequirementsAttachmentEditing
      RequirementsCollection RequirementsCollectionEditing
      RequirementsDPartInteract RequirementsDigSig RequirementsDigSigMDP
      RequirementsDigSigValidation RequirementsEnableJavaScripts
      RequirementsEncryption RequirementsGeospatial2D
      RequirementsGeospatial3D RequirementsHandler RequirementsMarkup
      RequirementsMultimedia RequirementsNavigation
      RequirementsOCAutoStates RequirementsOCInteract RequirementsPRC
      RequirementsRichMedia RequirementsSTEP
      RequirementsSeparationSimulation RequirementsTransitions
      RequirementsU3D RequirementsglTF
    ].map { |name| Pdfrb::Model::Type.const_get(name) }
    registry = Pdfrb::Model::Type.arlington_registry

    klasses.each do |klass|
      expect(registry[klass.name.split("::").last]).to eq(klass)
    end
    expect(klasses.size).to eq(28)
    expect(Pdfrb::Model::Type::RequirementsDigSig).to be < Pdfrb::Model::Type::RequirementsHandler
  end

  it "exposes the common handler keys" do
    handler = doc.add(
      { Type: :RequirementsHandler, S: :Encryption, V: 2.0,
        RH: { S: :JavaScript }, Penalty: :Fatal },
      type: Pdfrb::Model::Type::RequirementsEncryption
    )
    expect(handler.feature).to eq(:Encryption)
    expect(handler.version).to eq(2.0)
    expect(handler.reader_handler).not_to be_nil
    expect(handler).to be_fatal
    expect(handler.class.field(:RH).arlington).not_to be_nil
    expect(handler.script).to be_nil
  end

  it "exposes feature-specific keys" do
    digsig = doc.add({ S: :DigSig, V: 2.0, DigSig: { Handler: "Adobe.PPKLite" } },
                     type: Pdfrb::Model::Type::RequirementsDigSig)
    expect(digsig.dig_sig).not_to be_nil
    expect(digsig.class.field(:DigSig).arlington).not_to be_nil

    encrypt = doc.add({ S: :Encryption, V: 2.0, Encrypt: { Filter: "Standard" } },
                      type: Pdfrb::Model::Type::RequirementsEncryption)
    expect(encrypt.encrypt_dict).not_to be_nil

    gltf = doc.add({ S: :glTF, V: 2.0 },
                   type: Pdfrb::Model::Type::RequirementsglTF)
    expect(gltf.class.field(:V).arlington).not_to be_nil
    expect(gltf.class.field(:Penalty).arlington).not_to be_nil
  end
end
