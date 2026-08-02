# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Document do
  let(:doc) { described_class.new }

  it "starts empty" do
    expect(doc.io).to be_nil
  end

  describe "#wrap" do
    it "wraps a Hash as a Dictionary" do
      obj = doc.wrap({ Type: :Foo })
      expect(obj).to be_a(Pdfrb::Model::Cos::Dictionary)
    end

    it "wraps an Array as a PdfArray" do
      obj = doc.wrap([1, 2, 3])
      expect(obj).to be_a(Pdfrb::Model::PdfArray)
    end

    it "uses an explicit type when given" do
      klass = Class.new(Pdfrb::Model::Cos::Dictionary)
      obj = doc.wrap({ A: 1 }, type: klass)
      expect(obj).to be_a(klass)
    end

    it "looks up the typed class via the type registry" do
      klass = Class.new(Pdfrb::Model::Cos::Dictionary)
      Pdfrb::Model::Cos::Dictionary.register_type(:WrapTest, klass)
      obj = doc.wrap({ Type: :WrapTest })
      expect(obj).to be_a(klass)
    end

    it "carries the document reference" do
      obj = doc.wrap({})
      expect(obj.document).to be(doc)
    end
  end

  describe "#add" do
    it "allocates a fresh oid and registers the object" do
      obj = doc.add({ Type: :Foo })
      expect(obj.oid).to be > 0
      expect(doc.object(Pdfrb::Model::Reference.new(obj.oid, 0))).to be(obj)
    end

    it "monotonically allocates oids" do
      a = doc.add({})
      b = doc.add({})
      expect(b.oid).to be > a.oid
    end
  end

  describe "#dereference" do
    it "passes through non-References" do
      expect(doc.dereference(:Foo)).to eq(:Foo)
    end

    it "resolves a Reference to an indirect object" do
      obj = doc.add({ Type: :Foo })
      ref = Pdfrb::Model::Reference.new(obj.oid, 0)
      expect(doc.dereference(ref)).to be(obj)
    end

    it "returns nil for a dangling reference" do
      ref = Pdfrb::Model::Reference.new(999, 0)
      expect(doc.dereference(ref)).to be_nil
    end
  end

  describe "message dispatch" do
    it "delivers messages to registered listeners" do
      received = []
      doc.register_listener(:ping) { |x| received << x }
      doc.dispatch_message(:ping, "hello")
      expect(received).to eq(["hello"])
    end
  end
end
