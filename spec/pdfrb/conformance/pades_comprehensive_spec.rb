# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Conformance::Pades do
  describe "comprehensive" do
    let(:doc) { Pdfrb::Document.new }

    def add_signature_field(name:, v: nil, ft: :Sig)
      field = doc.add(
        { Type: :Annot, Subtype: :Widget, T: name, FT: ft, V: v },
        type: Pdfrb::Model::Type::Field
      )
      acroform = doc.catalog.value[:AcroForm] ||= { Fields: [] }
      acroform[:Fields] ||= []
      acroform[:Fields] << Pdfrb::Model::Reference.new(field.oid, field.gen)
      field
    end

    describe "level B-B" do
      it "passes when a Sig field with valid /V is present" do
        v = { Type: :Sig, ByteRange: [0, 100, 200, 50], Contents: "x" * 1024 }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-B")
        expect(result.violations.map(&:rule_id)).not_to include("pades-1", "bb-1")
      end

      it "flags a Sig field with bogus /V /Type" do
        v = { Type: :Bogus }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-B")
        expect(result.violations.map(&:rule_id)).to include("bb-1")
      end
    end

    describe "level B-T" do
      it "flags when signature has no timestamp component" do
        v = { Type: :Sig, ByteRange: [0, 10], Contents: "short" }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-T")
        expect(result.violations.map(&:rule_id)).to include("bt-1")
      end

      it "passes when signature is a DocTimeStamp" do
        v = { Type: :DocTimeStamp }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-T")
        expect(result.violations.map(&:rule_id)).not_to include("bt-1")
      end

      it "passes when Contents bytesize exceeds 1024 (timestamp token)" do
        v = { Type: :Sig, ByteRange: [0, 100, 200, 50],
              Contents: "x" * 2048 }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-T")
        expect(result.violations.map(&:rule_id)).not_to include("bt-1")
      end
    end

    describe "level B-LT" do
      it "requires /DSS on Catalog" do
        v = { Type: :Sig, ByteRange: [0, 100], Contents: "x" * 2048 }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-LT")
        expect(result.violations.map(&:rule_id)).to include("blt-1")
      end

      it "passes when /DSS is present" do
        v = { Type: :Sig, ByteRange: [0, 100], Contents: "x" * 2048 }
        add_signature_field(name: "sig1", v: v)
        doc.catalog.value[:DSS] = { Certs: [] }
        result = described_class.validate(doc, level: :"B-LT")
        expect(result.violations.map(&:rule_id)).not_to include("blt-1")
      end
    end

    describe "level B-LTA" do
      it "requires an archival Document Time Stamp" do
        v = { Type: :Sig, ByteRange: [0, 100], Contents: "x" * 2048 }
        add_signature_field(name: "sig1", v: v)
        doc.catalog.value[:DSS] = { Certs: [] }
        result = described_class.validate(doc, level: :"B-LTA")
        expect(result.violations.map(&:rule_id)).to include("blta-1")
      end

      it "passes when a DocTimeStamp field is present" do
        v = { Type: :Sig, ByteRange: [0, 100], Contents: "x" * 2048 }
        add_signature_field(name: "sig1", v: v)
        ts_v = { Type: :DocTimeStamp }
        add_signature_field(name: "archive", v: ts_v)
        doc.catalog.value[:DSS] = { Certs: [] }
        result = described_class.validate(doc, level: :"B-LTA")
        expect(result.violations.map(&:rule_id)).not_to include("blta-1")
      end
    end

    describe "level chaining" do
      it "B-LTA inherits B-LT rules" do
        result = described_class.validate(doc, level: :"B-LTA")
        # Both B-LT (blt-1) and B-LTA rules apply.
        expect(result.violations.map(&:rule_id)).to include("blt-1")
      end

      it "B-LT inherits B-T rules" do
        v = { Type: :Sig, ByteRange: [0, 100], Contents: "short" }
        add_signature_field(name: "sig1", v: v)
        result = described_class.validate(doc, level: :"B-LT")
        expect(result.violations.map(&:rule_id)).to include("bt-1", "blt-1")
      end
    end

    describe ".signature_fields helper" do
      it "filters AcroForm fields to /FT /Sig" do
        add_signature_field(name: "sig1")
        doc.form.add_text_field("text1", page: doc.pages.add,
                                         rect: [0, 0, 100, 20])
        fields = described_class.signature_fields(doc)
        expect(fields.length).to eq(1)
        expect(fields.first[:T]).to eq("sig1")
      end

      it "returns empty array when AcroForm is absent" do
        expect(described_class.signature_fields(doc)).to eq([])
      end
    end
  end
end
