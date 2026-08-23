# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 29 field/filespec mappings" do
  let(:doc) { Pdfrb::Document.new }

  describe "registry wiring" do
    it "registers all mapped classes under their TSVs" do
      registry = Pdfrb::Model::Type.arlington_registry
      {
        Pdfrb::Model::Type::Field => "Field",
        Pdfrb::Model::Type::Choice => "FieldChoice",
        Pdfrb::Model::Type::TextField => "FieldTx",
        Pdfrb::Model::Type::SignatureField => "FieldSig",
        Pdfrb::Model::Type::CheckboxButton => "FieldBtnCheckbox",
        Pdfrb::Model::Type::PushButton => "FieldBtnPush",
        Pdfrb::Model::Type::RadioButton => "FieldBtnRadio",
        Pdfrb::Model::Type::FileSpecEF => "FileSpecEF",
        Pdfrb::Model::Type::FileSpecRF => "FileSpecRF",
        Pdfrb::Model::Type::EmbeddedFileParameter => "EmbeddedFileParameter",
        Pdfrb::Model::Type::MarkedContentReference => "MarkedContentReference",
        Pdfrb::Model::Type::ObjectReference => "ObjectReference",
        Pdfrb::Model::Type::Namespace => "Namespace",
        Pdfrb::Model::Type::SoftwareIdentifier => "SoftwareIdentifier",
        Pdfrb::Model::Type::Transition => "Transition",
        Pdfrb::Model::Type::ExData3DMarkup => "ExData3DMarkup",
        Pdfrb::Model::Type::ExDataMarkupGeo => "ExDataMarkupGeo",
        Pdfrb::Model::Type::PrinterMarkSubDict => "AppearancePrinterMarkSubDict",
      }.each do |klass, tsv|
        expect(registry[tsv]).to eq(klass), tsv
      end
    end
  end

  describe "form field family" do
    it "materializes base field metadata" do
      field = doc.add({ T: "username", Ff: 0 },
                      type: Pdfrb::Model::Type::Field)
      expect(field.class.field(:T).arlington).not_to be_nil
      expect(field.class.field(:Ff).arlington).not_to be_nil
      expect(field.class.field(:AA).arlington).not_to be_nil
    end

    it "materializes per-subtype metadata" do
      choice = doc.add({ FT: :Ch, Opt: ["A", "B"] },
                       type: Pdfrb::Model::Type::Choice)
      expect(choice.class.field(:Opt).arlington).not_to be_nil
      expect(choice.class.field(:TI).arlington).not_to be_nil

      text = doc.add({ FT: :Tx, MaxLen: 50 },
                     type: Pdfrb::Model::Type::TextField)
      expect(text.class.field(:MaxLen).arlington).not_to be_nil

      sig = doc.add({ FT: :Sig }, type: Pdfrb::Model::Type::SignatureField)
      expect(sig.class.field(:Lock).arlington).not_to be_nil
      expect(sig.class.field(:SV).arlington).not_to be_nil
    end

    it "adds the three button subclasses" do
      checkbox = doc.add({ FT: :Btn }, type: Pdfrb::Model::Type::CheckboxButton)
      expect(checkbox).to be_checkbox
      expect(checkbox.class.field(:Opt).arlington).not_to be_nil

      push = doc.add({ FT: :Btn, Ff: 0x10000 },
                     type: Pdfrb::Model::Type::PushButton)
      expect(push).to be_push_button
      expect(push).not_to be_radio

      radio = doc.add({ FT: :Btn, Ff: 0x8000 },
                      type: Pdfrb::Model::Type::RadioButton)
      expect(radio).to be_radio
      expect(radio).not_to be_push_button
    end
  end

  describe "file specification family" do
    it "materializes EF and RF metadata" do
      ef = doc.add({ F: { Type: :EmbeddedFile } },
                   type: Pdfrb::Model::Type::FileSpecEF)
      expect(ef.class.field(:F).arlington).not_to be_nil
      expect(ef.class.field(:UF).arlington).not_to be_nil

      rf = doc.add({ F: [] }, type: Pdfrb::Model::Type::FileSpecRF)
      expect(rf.class.field(:F).arlington).not_to be_nil

      params = doc.add({ Size: 1024, CheckSum: "abc" },
                       type: Pdfrb::Model::Type::EmbeddedFileParameter)
      expect(params.class.field(:Size).arlington).not_to be_nil
    end
  end

  describe "structure references" do
    it "materializes marked-content and object references" do
      mc = doc.add({ Pg: 0, MCID: 3 },
                   type: Pdfrb::Model::Type::MarkedContentReference)
      expect(mc.class.field(:Pg).arlington).not_to be_nil
      expect(mc.class.field(:MCID).arlington).not_to be_nil

      obj_ref = doc.add({ Pg: 0, Obj: 5 },
                        type: Pdfrb::Model::Type::ObjectReference)
      expect(obj_ref.class.field(:Pg).arlington).not_to be_nil
      expect(obj_ref.class.field(:Obj).arlington).not_to be_nil
    end
  end

  describe "namespace and software" do
    it "materializes metadata" do
      ns = doc.add({ Type: :Namespace, NS: "http://example.org/ns" },
                   type: Pdfrb::Model::Type::Namespace)
      expect(ns.class.field(:NS).arlington).not_to be_nil
      expect(ns.class.field(:Schema).arlington).not_to be_nil

      sw = doc.add({ U: "Acrobat", L: [] },
                   type: Pdfrb::Model::Type::SoftwareIdentifier)
      expect(sw.class.field(:U).arlington).not_to be_nil
      expect(sw.class.field(:L).arlington).not_to be_nil
    end
  end

  describe "transition family" do
    it "materializes transition and ex-data metadata" do
      tr = doc.add({ Type: :Trans, S: :Fade, D: 1.5 },
                   type: Pdfrb::Model::Type::Transition)
      expect(tr.class.field(:S).arlington).not_to be_nil
      expect(tr.class.field(:D).arlington).not_to be_nil

      markup = doc.add({ Type: :ExData, Subtype: :"3D" },
                       type: Pdfrb::Model::Type::ExData3DMarkup)
      expect(markup.class.field(:Subtype).arlington).not_to be_nil

      geo = doc.add({ Type: :ExData, Subtype: :MarkupGeo },
                    type: Pdfrb::Model::Type::ExDataMarkupGeo)
      expect(geo.class.field(:Subtype).arlington).not_to be_nil

      pm = doc.add({ F: :MyFont },
                   type: Pdfrb::Model::Type::PrinterMarkSubDict)
      expect(pm.class.field(:*)).not_to be_nil
    end
  end
end
