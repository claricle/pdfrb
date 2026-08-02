# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Task::Optimize do
  it "produces valid output" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Optimize me", at: [72, 720], font: font, size: 12)

    out = StringIO.new
    described_class.call(doc, io: out)
    bytes = out.string
    expect(bytes).to start_with("%PDF-")
    expect(bytes).to include("%%EOF")
  end

  it "uses xref stream" do
    doc = Pdfrb::Document.new
    doc.pages.add

    out = StringIO.new
    described_class.call(doc, io: out)
    expect(out.string).to match(%r{/Type\s*/XRef})
  end

  it "round-trips" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Round-trip", at: [72, 720], font: font, size: 12)

    out = StringIO.new
    described_class.call(doc, io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    expect(reloaded.pages.count).to eq(1)
  end
end

RSpec.describe Pdfrb::Document::Outline do
  let(:doc) { Pdfrb::Document.new }

  it "creates a flat outline" do
    doc.outline.add("Chapter 1")
    doc.outline.add("Chapter 2")
    doc.outline.build!

    expect(doc.catalog.value[:Outlines]).not_to be_nil
  end

  it "round-trips through write+read" do
    doc.outline.add("Chapter 1")
    doc.outline.add("Chapter 2")
    doc.outline.build!

    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    outlines_ref = reloaded.catalog[:Outlines]
    expect(outlines_ref).not_to be_nil
    outlines = reloaded.object(outlines_ref)
    expect(outlines[:Type]).to eq(:Outlines)
  end

  it "supports nested entries" do
    ch1 = doc.outline.add("Chapter 1")
    doc.outline.add("Section 1.1", parent: ch1)
    doc.outline.add("Section 1.2", parent: ch1)
    doc.outline.add("Chapter 2")
    doc.outline.build!

    out = StringIO.new
    doc.write(io: out)

    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    outlines = reloaded.object(reloaded.catalog[:Outlines])
    expect(outlines[:Count]).to be >= 2
  end
end
