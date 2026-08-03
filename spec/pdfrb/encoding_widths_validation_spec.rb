# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Canvas text encoding integration" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }

  it "encodes text using WinAnsiEncoding for registered fonts" do
    font = doc.fonts.add("Helvetica")
    page.canvas.text("café", at: [72, 720], font: font, size: 12)

    contents = page.value[:Contents]
    stream = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
    data = stream&.stream || ""

    # WinAnsi 'é' is 0xE9, not UTF-8 \xC3\xA9
    expect(data).to include("\xE9".b)
    expect(data).not_to include("\xC3\xA9".b)
  end

  it "encodes em-dash as WinAnsi 0x97" do
    font = doc.fonts.add("Times-Roman")
    page.canvas.text("A—B", at: [0, 0], font: font, size: 12)

    contents = page.value[:Contents]
    stream = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
    data = stream&.stream || ""
    expect(data).to include("\x97".b)
  end

  it "encodes curly quotes" do
    font = doc.fonts.add("Courier")
    page.canvas.text("“test”", at: [0, 0], font: font, size: 12)

    contents = page.value[:Contents]
    stream = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
    data = stream&.stream || ""
    expect(data).to include("\x93".b)
    expect(data).to include("\x94".b)
  end

  it "passes through ASCII unchanged" do
    font = doc.fonts.add("Helvetica")
    page.canvas.text("Hello", at: [0, 0], font: font, size: 12)

    contents = page.value[:Contents]
    stream = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
    data = stream&.stream || ""
    expect(data).to include("Hello")
  end

  it "substitutes unencodable characters with ?" do
    font = doc.fonts.add("Helvetica")
    page.canvas.text("中文", at: [0, 0], font: font, size: 12)

    contents = page.value[:Contents]
    stream = contents.is_a?(Pdfrb::Model::Reference) ? doc.object(contents) : contents
    data = stream&.stream || ""
    expect(data).to include("??")
  end
end

RSpec.describe "Font /Widths array" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "populates /Widths from AFM metrics" do
    doc.fonts.add("Helvetica")
    font_ref = doc.catalog.value[:Resources][:Font][:F1]
    font = doc.object(font_ref)

    expect(font.value[:FirstChar]).to eq(0)
    expect(font.value[:LastChar]).to eq(255)
    expect(font.value[:Widths]).to be_an(Array)
    expect(font.value[:Widths].length).to eq(256)
  end

  it "has non-zero width for space (0x20)" do
    doc.fonts.add("Helvetica")
    font_ref = doc.catalog.value[:Resources][:Font][:F1]
    font = doc.object(font_ref)

    space_width = font.value[:Widths][0x20]
    expect(space_width).to be_positive
  end

  it "has non-zero width for 'H' (0x48)" do
    doc.fonts.add("Helvetica")
    font_ref = doc.catalog.value[:Resources][:Font][:F1]
    font = doc.object(font_ref)

    h_width = font.value[:Widths][0x48]
    expect(h_width).to be_positive
  end

  it "widths are consistent with text_width measurement" do
    doc.fonts.add("Times-Roman")
    font_ref = doc.catalog.value[:Resources][:Font][:F1]
    font = doc.object(font_ref)

    measured = doc.fonts.text_width("A", "Times-Roman", size: 1000)
    widths_array_a = font.value[:Widths][0x41]

    expect(measured).to be_within(1.0).of(widths_array_a)
  end
end

RSpec.describe Pdfrb::Validator do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "validates a well-formed document" do
    errors = described_class.validate(doc)
    expect(errors).to be_empty
  end

  it "detects missing MediaBox" do
    bad_doc = Pdfrb::Document.new
    pages_ref = bad_doc.catalog.value[:Pages]
    pages_obj = pages_ref.is_a?(Pdfrb::Model::Reference) ? bad_doc.object(pages_ref) : pages_ref
    page = bad_doc.add({ Type: :Page },
                       type: Pdfrb::Model::Type::Page)
    pages_obj.value[:Kids] << Pdfrb::Model::Reference.new(page.oid, page.gen)
    pages_obj.value[:Count] = 1

    errors = described_class.validate(bad_doc)
    expect(errors).to include(include("MediaBox"))
  end

  it "detects unresolved references" do
    doc.catalog.value[:BOGus] = Pdfrb::Model::Reference.new(99998, 0)

    errors = described_class.validate(doc)
    expect(errors.any? { |e| e.include?("unresolved") }).to be true
  end

  it "validate! raises on invalid document" do
    doc.catalog.value[:BOGus] = Pdfrb::Model::Reference.new(99998, 0)
    expect { described_class.validate!(doc) }.to raise_error(Pdfrb::ValidationError)
  end

  it "validate! returns true for valid document" do
    expect(described_class.validate!(doc)).to be true
  end
end
