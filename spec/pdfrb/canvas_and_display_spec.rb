# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::Canvas do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "emits BDC/EMC for tagged content with MCID" do
    canvas.tagged(:P, mcid: 0) do
      canvas.text("Hello", at: [72, 720], font: :F1, size: 12)
    end
    page.value[:Contents]
    canvas.is_a?(Pdfrb::Model::Reference) ? doc.object(canvas).stream : ""
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("BDC")
    expect(data).to include("MCID")
    expect(data).to include("EMC")
  end

  it "emits BMC/EMC for artifacts" do
    canvas.artifact do
      canvas.text("Page 1", at: [72, 36], font: :F1, size: 8)
    end
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("/Artifact")
    expect(data).to include("BMC")
    expect(data).to include("EMC")
  end

  it "supports explicit end_marked_content" do
    canvas.marked_content(:Figure, { MCID: 1 })
    canvas.end_marked_content
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("BDC")
    expect(data).to include("EMC")
  end

  it "supports artifact with type" do
    canvas.artifact(:Background) do
      canvas.rectangle(0, 0, 612, 792)
    end
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("Background")
  end

  it "tagged without mcid emits BMC (no properties needed)" do
    canvas.tagged(:Sect) { canvas.text("x", at: [0, 0], font: :F1, size: 12) }
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("BMC")
  end
end

RSpec.describe Pdfrb::Document::Display do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "sets page layout" do
    doc.display.page_layout = :TwoColumnRight
    expect(doc.catalog.value[:PageLayout]).to eq(:TwoColumnRight)
  end

  it "rejects invalid page layout" do
    expect { doc.display.page_layout = :BadLayout }.to raise_error(ArgumentError)
  end

  it "sets page mode" do
    doc.display.page_mode = :UseOutlines
    expect(doc.catalog.value[:PageMode]).to eq(:UseOutlines)
  end

  it "sets open action destination" do
    doc.display.open_action = [Pdfrb::Model::Reference.new(3, 0), :Fit]
    expect(doc.catalog.value[:OpenAction]).not_to be_nil
  end

  it "sets viewer preferences" do
    doc.display.viewer_preferences(HideToolbar: true, FitWindow: true)
    vp = doc.catalog.value[:ViewerPreferences]
    expect(vp[:HideToolbar]).to be true
    expect(vp[:FitWindow]).to be true
  end

  it "reads viewer preferences" do
    doc.display.viewer_preferences(CenterWindow: true)
    expect(doc.display.viewer_preferences[:CenterWindow]).to be true
  end

  it "presentation mode sets fullscreen and hides UI" do
    doc.display.presentation_mode!
    expect(doc.catalog.value[:PageMode]).to eq(:FullScreen)
    vp = doc.catalog.value[:ViewerPreferences]
    expect(vp[:HideToolbar]).to be true
    expect(vp[:DisplayDocTitle]).to be true
  end

  it "round-trips through serialization" do
    doc.display.page_layout = :OneColumn
    doc.display.viewer_preferences(FitWindow: true)
    io = StringIO.new
    doc.write(io: io)
    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reparsed.catalog.value[:PageLayout]).to eq(:OneColumn)
  end
end

RSpec.describe Pdfrb::Conformance::PdfA do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "A-2 has at least shared rules" do
    expect(described_class::A2.rules.length).to be >= described_class::SHARED.rules.length
  end

  it "A-3 has at least shared rules" do
    expect(described_class::A3.rules.length).to be >= described_class::SHARED.rules.length
  end

  it "A-2 warns about PostScript XObjects" do
    ps_stream = doc.add(
      { Type: :XObject, Subtype: :PS },
      type: Pdfrb::Model::Cos::Stream
    )
    _ = ps_stream

    result = described_class.validate(doc, level: :a2b)
    v = result.violations.find { |x| x.rule_id == "a2-1" }
    expect(v).not_to be_nil
  end

  it "A-3 flags embedded files without AFRelationship" do
    doc.catalog.value[:Metadata] = Pdfrb::Model::Reference.new(999, 0)
    doc.add(
      { Type: :EmbeddedFile, Length: 3 },
      type: Pdfrb::Model::Cos::Stream
    )
    filespec = doc.add(
      { Type: :Filespec, F: "data.bin", EF: {} },
      type: Pdfrb::Model::Cos::Dictionary
    )
    _ = filespec

    result = described_class.validate(doc, level: :a3b)
    v = result.violations.find { |x| x.rule_id == "a3-1" }
    expect(v).not_to be_nil
  end
end
