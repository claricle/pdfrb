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

  describe "stream deduplication" do
    it "replaces duplicate streams with a single shared reference" do
      doc = Pdfrb::Document.new
      page = doc.pages.add
      payload = "x" * 500

      stream1 = doc.add({ Type: :XObject, Subtype: :Form, BBox: [0, 0, 1, 1] },
                        type: Pdfrb::Model::Cos::Stream)
      stream1.stream = payload.dup

      stream2 = doc.add({ Type: :XObject, Subtype: :Form, BBox: [0, 0, 1, 1] },
                        type: Pdfrb::Model::Cos::Stream)
      stream2.stream = payload.dup

      resources = page.value[:Resources] = {}
      resources[:XObject] = {
        Fm1: Pdfrb::Model::Reference.new(stream1.oid, 0),
        Fm2: Pdfrb::Model::Reference.new(stream2.oid, 0),
      }

      replacements = described_class.dedup_streams!(doc)
      expect(replacements).to include(stream2.oid => stream1.oid)

      xobject_refs = resources[:XObject].values.map(&:oid)
      expect(xobject_refs).to contain_exactly(stream1.oid, stream1.oid)
    end

    it "leaves unique streams alone" do
      doc = Pdfrb::Document.new
      s1 = doc.add({ Subtype: :Form }, type: Pdfrb::Model::Cos::Stream)
      s1.stream = "alpha"
      s2 = doc.add({ Subtype: :Form }, type: Pdfrb::Model::Cos::Stream)
      s2.stream = "beta"

      replacements = described_class.dedup_streams!(doc)
      expect(replacements).to be_empty
    end

    it "produces smaller output for duplicate-heavy documents" do
      dedup_doc = Pdfrb::Document.new
      dedup_page = dedup_doc.pages.add
      payload = "Z" * 800

      3.times do |i|
        stream = dedup_doc.add({ Subtype: :Form }, type: Pdfrb::Model::Cos::Stream)
        stream.stream = payload.dup
        dedup_page.value[:Resources] ||= {}
        dedup_page.value[:Resources][:XObject] ||= {}
        dedup_page.value[:Resources][:XObject][:"Fm#{i}"] =
          Pdfrb::Model::Reference.new(stream.oid, 0)
      end

      dedup_out = StringIO.new
      described_class.call(dedup_doc, io: dedup_out)

      nodup_doc = Pdfrb::Document.new
      nodup_page = nodup_doc.pages.add
      nodup_page.value[:Resources] = {}
      3.times do |i|
        stream = nodup_doc.add({ Subtype: :Form }, type: Pdfrb::Model::Cos::Stream)
        stream.stream = payload.dup
        nodup_page.value[:Resources][:XObject] ||= {}
        nodup_page.value[:Resources][:XObject][:"Fm#{i}"] =
          Pdfrb::Model::Reference.new(stream.oid, 0)
      end
      nodup_out = StringIO.new
      described_class.call(nodup_doc, io: nodup_out, dedup: false)

      expect(dedup_out.string.bytesize).to be < nodup_out.string.bytesize
    end
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
