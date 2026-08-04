# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Type::Font do
  let(:doc) { Pdfrb::Document.new }
  let(:font) do
    doc.add({ Type: :Font, Subtype: :Type1, BaseFont: :Helvetica,
              FirstChar: 0, LastChar: 255, Encoding: :WinAnsiEncoding },
            type: Pdfrb::Model::Type::FontType1)
  end

  it "reads subtype" do
    expect(font.subtype).to eq(:Type1)
  end

  it "reads base font" do
    expect(font.base_font).to eq(:Helvetica)
  end

  it "reads encoding" do
    expect(font.encoding).to eq(:WinAnsiEncoding)
  end

  it "identifies as simple font" do
    expect(font.simple?).to be true
    expect(font.cid?).to be false
    expect(font.type3?).to be false
  end

  it "has no font descriptor by default" do
    expect(font.font_descriptor).to be_nil
  end
end

RSpec.describe Pdfrb::Model::Type::Annotation do
  let(:doc) { Pdfrb::Document.new }
  let(:annot) do
    doc.add({ Type: :Annot, Subtype: :Link, Contents: "A link", F: 6 },
            type: Pdfrb::Model::Type::Annotation)
  end

  it "reads subtype" do
    expect(annot.subtype).to eq(:Link)
  end

  it "reads contents" do
    expect(annot.contents).to eq("A link")
  end

  it "reads flags" do
    expect(annot.flags).to eq(6)
  end

  it "checks flag predicates" do
    expect(annot.hidden?).to be false
    expect(annot.print?).to be true
    expect(annot.no_zoom?).to be true
  end
end

RSpec.describe Pdfrb::Encryption::StandardSecurityHandler do
  it "initializes from encrypt dict" do
    handler = described_class.new(
      Encrypt: { V: 2, R: 3, Length: 128, P: -4, O: "\x00" * 32, U: "\x00" * 32 },
      ID: ["test-id"]
    )
    expect(handler.version).to eq(2)
    expect(handler.revision).to eq(3)
    expect(handler.key_length).to eq(16)
  end
end
