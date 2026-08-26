# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::Canvas do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "emits W n for clip (nonzero winding)" do
    canvas.save_graphics_state do
      canvas.rectangle(100, 100, 200, 200)
      canvas.clip
    end
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("W")
    expect(data).to include("n")
  end

  it "emits W* n for clip_even_odd" do
    canvas.save_graphics_state do
      canvas.rectangle(0, 0, 100, 100)
      canvas.clip_even_odd
    end
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("W*")
    expect(data).to include("n")
  end

  it "registers ClipNonZero, ClipEvenOdd, InvokeXObject operators" do
    expect(Pdfrb::Content::Operator["W"]).not_to be_nil
    expect(Pdfrb::Content::Operator["W*"]).not_to be_nil
    expect(Pdfrb::Content::Operator["Do"]).not_to be_nil
  end

  it "emits q cm Do Q for draw_image_matrix" do
    canvas.draw_image_matrix(:Im1, a: 200, b: 0, c: 0, d: 150, e: 72, f: 300)
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("200")
    expect(data).to include("150")
    expect(data).to include("/Im1 Do")
  end

  it "tracks used XObjects via draw_image_matrix" do
    canvas.draw_image_matrix(:Im1, a: 100, b: 0, c: 0, d: 100, e: 0, f: 0)
    expect(canvas.used_xobjects).to include(:Im1)
  end
end

RSpec.describe Pdfrb::Model::Type::Page do
  it "sets MediaBox via setter" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    page.media_box = [0, 0, 595, 842]

    expect(page.media_box).to eq([0, 0, 595, 842])
  end

  it "allows custom page dimensions" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    page.media_box = [0, 0, 1000, 500]

    expect(page.value[:MediaBox]).to eq([0, 0, 1000, 500])
  end
end

RSpec.describe Pdfrb::Document::Fonts do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "measure_text returns width in points" do
    font = doc.fonts.add("Helvetica")
    width = doc.fonts.measure_text("Hello, World!", font: font, size: 12)
    expect(width).to be_a(Float)
    expect(width).to be_positive
  end

  it "measure_text is consistent with text_width" do
    font = doc.fonts.add("Times-Roman")
    w1 = doc.fonts.measure_text("Test", font: font, size: 14)
    w2 = doc.fonts.text_width("Test", "Times-Roman", size: 14)
    expect(w1).to be_within(0.01).of(w2)
  end

  it "metrics_for returns font metrics hash" do
    font = doc.fonts.add("Helvetica")
    metrics = doc.fonts.metrics_for(font)
    expect(metrics[:ascent]).to be_positive
    expect(metrics[:descent]).to be_negative
    expect(metrics[:cap_height]).to be_positive
    expect(metrics[:units_per_em]).to eq(1000)
  end

  it "loads a TrueType font from a file path" do
    path = "/System/Library/Fonts/Supplemental/Arial.ttf"
    skip "Arial.ttf not found" unless File.exist?(path)

    resource = doc.fonts.add(path)
    expect(resource).to be_a(Symbol)

    font_ref = doc.pages.pages_root.value[:Resources][:Font][resource]
    font = doc.object(font_ref)
    fd_ref = font.value[:FontDescriptor]
    expect(fd_ref).to be_a(Pdfrb::Model::Reference)

    fd = doc.object(fd_ref)
    expect(fd.value[:FontFile2]).to be_a(Pdfrb::Model::Reference)
  end

  it "handles non-existent file paths gracefully" do
    resource = doc.fonts.add("/nonexistent/font.ttf")
    expect(resource).to be_a(Symbol)
  end
end

RSpec.describe Pdfrb::Document::Structure do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "creates StructTreeRoot with elements" do
    doc.structure.enable!
    elem = doc.structure.add_element(:H1, title: "Title")
    expect(elem.value[:S]).to eq(:H1)
    expect(doc.catalog.value[:StructTreeRoot]).to be_a(Pdfrb::Model::Reference)
  end

  it "sets MarkInfo when enabled" do
    doc.structure.enable!
    mark_ref = doc.catalog.value[:MarkInfo]
    expect(mark_ref).to be_a(Pdfrb::Model::Reference)
    mark = doc.object(mark_ref)
    expect(mark.value[:Marked]).to be true
  end

  it "supports nested structure elements" do
    doc.structure.enable!
    parent = doc.structure.add_element(:Div)
    child = doc.structure.add_child(parent, :P)
    expect(child.value[:P]).to be_a(Pdfrb::Model::Reference)
    expect(child.value[:P].oid).to eq(parent.oid)
  end

  it "supports role mapping" do
    doc.structure.enable!
    doc.structure.map_role(:Heading1, :H1)
    role_map = doc.structure.root.value[:RoleMap]
    expect(role_map[:Heading1]).to eq(:H1)
  end
end
