# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Annotation do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }

  it "registers all standard annotation subtypes" do
    expect(described_class.subtypes).to include(
      :Link, :Text, :FreeText, :Stamp, :Popup,
      :FileAttachment, :Highlight, :Underline, :Squiggly,
      :StrikeOut, :Square, :Circle
    )
  end

  it "creates a Link annotation with correct subtype" do
    annot = described_class.create(:Link, document: doc, page: page, rect: [0, 0, 100, 100])
    expect(annot[:Subtype]).to eq(:Link)
    expect(annot[:Type]).to eq(:Annot)
    expect(annot[:H]).to eq(:I)
  end

  it "creates a Text annotation with default Name" do
    annot = described_class.create(:Text, document: doc, page: page,
                                          rect: [0, 0, 50, 50], contents: "Note")
    expect(annot[:Subtype]).to eq(:Text)
    expect(annot[:Name]).to eq(:Comment)
    expect(annot[:Contents]).to eq("Note")
  end

  it "creates a FileAttachment with PushPin icon" do
    annot = described_class.create(:FileAttachment, document: doc, page: page,
                                                    rect: [0, 0, 20, 20])
    expect(annot[:Subtype]).to eq(:FileAttachment)
    expect(annot[:Name]).to eq(:PushPin)
  end

  it "attaches annotation to page /Annots" do
    described_class.create(:Link, document: doc, page: page, rect: [0, 0, 10, 10])
    expect(page.value[:Annots].length).to eq(1)
  end

  it "allows custom annotation types via registration (OCP)" do
    custom = Class.new(Pdfrb::Annotation::Base) do
      class << self
        def subtype; :Watermark; end

        def default_fields
          { W: 1.0 }
        end
      end
      register_as
    end

    expect(described_class[:Watermark]).to be(custom)
    annot = described_class.create(:Watermark, document: doc, page: page,
                                               rect: [0, 0, 10, 10])
    expect(annot[:Subtype]).to eq(:Watermark)
    expect(annot[:W]).to eq(1.0)
  end

  it "passes through type-specific options" do
    annot = described_class.create(:Link, document: doc, page: page,
                                          rect: [0, 0, 10, 10],
                                          color: [1.0, 0.0, 0.0],
                                          border: [0, 0, 1])
    expect(annot[:C]).to eq([1.0, 0.0, 0.0])
    expect(annot[:Border]).to eq([0, 0, 1])
  end
end

RSpec.describe Pdfrb::Document::Annotations do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }

  it "adds annotations via the facade" do
    doc.annotations.add(page, subtype: :Link, rect: [0, 0, 100, 50])
    expect(page.value[:Annots].length).to eq(1)
  end

  it "provides convenience methods for common types" do
    doc.annotations.add_text_note(page, rect: [0, 0, 50, 50], contents: "Hi")
    annot = doc.annotations.each(page).first
    expect(annot[:Subtype]).to eq(:Text)
  end

  it "counts annotations on a page" do
    expect(doc.annotations.count(page)).to eq(0)
    doc.annotations.add(page, subtype: :Link, rect: [0, 0, 10, 10])
    doc.annotations.add(page, subtype: :Text, rect: [0, 0, 10, 10])
    expect(doc.annotations.count(page)).to eq(2)
  end

  it "round-trips through serialization" do
    doc.annotations.add_link(page, rect: [10, 10, 100, 50], dest: [1, :XYZ, 0, 0, nil])
    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    annots = reparsed.pages.first.value[:Annots]
    expect(annots).not_to be_nil
    expect(annots.length).to eq(1)
  end
end
