# frozen_string_literal: true

require "spec_helper"
require "stringio"

# End-to-end milestone: create a PDF from scratch, draw text and a
# rectangle on a page, write it, re-read it, and verify the content
# stream contains the expected operators.
RSpec.describe "end-to-end drawing via Canvas" do
  it "creates a one-page PDF with text and a shape" do
    src = Pdfrb::Document.new
    # Add a Page dict and a /Contents stream.
    contents = src.add({}, type: Pdfrb::Model::Cos::Stream)
    page = src.add({
      Type: :Page,
      MediaBox: [0, 0, 612, 792],
      Resources: { Font: { F1: Pdfrb::Model::Reference.new(99, 0) } },
      Contents: Pdfrb::Model::Reference.new(contents.oid, 0)
    })
    # Attach the page to the existing pages tree.
    pages_node = src.object(src.catalog.value[:Pages])
    pages_node.value[:Kids] = [Pdfrb::Model::Reference.new(page.oid, 0)]
    pages_node.value[:Count] = 1

    canvas = Pdfrb::Content::Canvas.new(contents)
    canvas.fill_color([:rgb, 0, 0, 1]).rectangle(72, 700, 200, 50).fill_stroke
    canvas.text("Hello, PDF!", at: [80, 720], font: :F1, size: 24)
    canvas.line(72, 600, 300, 600).stroke

    # Write it out and re-read.
    out = StringIO.new
    Pdfrb::Writer.write(src, out)

    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    page2 = dest.object(dest.catalog.value[:Pages])
    page2_node = dest.object(page2.value[:Kids].first)
    contents2 = dest.object(page2_node.value[:Contents])
    payload = contents2.decoded_stream

    expect(payload).to include("0 0 1 rg")
    expect(payload).to include("72 700 200 50 re")
    expect(payload).to include("B")        # fill+stroke
    expect(payload).to include("/F1 24 Tf")
    expect(payload).to include("(Hello, PDF!) Tj")
    expect(payload).to include("72 600 m\n300 600 l\n")
    expect(payload).to include("S\n")
  end

  it "preserves a content stream through read -> write -> read" do
    original_payload = <<~PDF
      BT
      /F1 12 Tf
      100 700 Td
      (Original text) Tj
      ET
    PDF

    src = Pdfrb::Document.new
    contents = src.add({}, type: Pdfrb::Model::Cos::Stream)
    contents.stream = original_payload.b
    page = src.add({
      Type: :Page,
      MediaBox: [0, 0, 612, 792],
      Resources: { Font: { F1: Pdfrb::Model::Reference.new(99, 0) } },
      Contents: Pdfrb::Model::Reference.new(contents.oid, 0)
    })
    pages_node = src.object(src.catalog.value[:Pages])
    pages_node.value[:Kids] = [Pdfrb::Model::Reference.new(page.oid, 0)]
    pages_node.value[:Count] = 1

    out = StringIO.new
    Pdfrb::Writer.write(src, out)

    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    pages2 = dest.object(dest.catalog.value[:Pages])
    page2 = dest.object(pages2.value[:Kids].first)
    contents2 = dest.object(page2.value[:Contents])
    expect(contents2.decoded_stream).to include("/F1 12 Tf")
    expect(contents2.decoded_stream).to include("(Original text) Tj")
  end
end
