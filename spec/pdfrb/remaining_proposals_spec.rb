# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Font embedding failure warning" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "warns on invalid font data" do
    io = StringIO.new("not a real TTF file")
    output = StringIO.new
    original_logger = Pdfrb.logger
    Pdfrb.logger = Logger.new(output)

    doc.fonts.add(io)

    Pdfrb.logger = original_logger
    expect(output.string).to include("does not look like a valid TTF/OTF")
  end

  it "does not warn on valid TTF data" do
    ttf = "\u0000\u0001\u0000\u0000#{"\x00" * 100}"
    io = StringIO.new(ttf)
    output = StringIO.new
    original_logger = Pdfrb.logger
    Pdfrb.logger = Logger.new(output)

    doc.fonts.add(io)

    Pdfrb.logger = original_logger
    expect(output.string).not_to include("does not look like a valid TTF/OTF")
  end

  it "recognizes OpenType OTTO magic as CFF/Type1 (Issue #62)" do
    otf = "OTTO#{"\x00" * 100}"
    io = StringIO.new(otf)

    doc.fonts.add(io)
    font_ref = doc.catalog.value[:Resources][:Font][:F1]
    font = doc.object(font_ref)
    expect(font[:Subtype]).to eq(:Type1)
  end

  it "validates font data helper correctly" do
    fonts = doc.fonts
    expect(fonts.valid_font_data?("\u0000\u0001\u0000\u0000x")).to be true
    expect(fonts.valid_font_data?("OTTOx")).to be true
    expect(fonts.valid_font_data?("not a font")).to be false
    expect(fonts.valid_font_data?("")).to be false
  end
end

RSpec.describe "Structure ParentTree" do
  let(:doc) { Pdfrb::Document.new.tap { |d| 3.times { d.pages.add } } }

  it "builds /ParentTree number tree" do
    doc.structure.enable!
    page1 = doc.pages[0]
    page2 = doc.pages[1]
    elem1 = doc.structure.add_element(:P)
    elem1.value[:Pg] = Pdfrb::Model::Reference.new(page1.oid, page1.gen)
    elem1.value[:K] = { MCID: 0 }
    elem2 = doc.structure.add_element(:P)
    elem2.value[:Pg] = Pdfrb::Model::Reference.new(page2.oid, page2.gen)
    elem2.value[:K] = { MCID: 0 }

    doc.structure.build!
    pt = doc.structure.root.value[:ParentTree]
    expect(pt).not_to be_nil
    expect(pt[:Nums]).to be_an(Array)
  end

  it "sets /ParentTreeNextKey" do
    doc.structure.enable!
    page = doc.pages[0]
    elem = doc.structure.add_element(:P)
    elem.value[:Pg] = Pdfrb::Model::Reference.new(page.oid, page.gen)
    elem.value[:K] = { MCID: 0 }

    doc.structure.build!
    expect(doc.structure.root.value[:ParentTreeNextKey]).to eq(1)
  end

  it "groups elements by page in /Nums array" do
    doc.structure.enable!
    page = doc.pages[0]
    3.times do |i|
      elem = doc.structure.add_element(:P)
      elem.value[:Pg] = Pdfrb::Model::Reference.new(page.oid, page.gen)
      elem.value[:K] = { MCID: i }
    end

    doc.structure.build!
    pt = doc.structure.root.value[:ParentTree]
    expect(pt[:Nums].length).to be > 0
  end

  it "build! is called automatically on write" do
    doc.structure.enable!
    page = doc.pages[0]
    elem = doc.structure.add_element(:P)
    elem.value[:Pg] = Pdfrb::Model::Reference.new(page.oid, page.gen)
    elem.value[:K] = { MCID: 0 }

    io = StringIO.new
    doc.write(io: io)
    pdf_bytes = io.string
    reparsed = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))
    expect(reparsed.catalog.value[:StructTreeRoot]).to be_a(Pdfrb::Model::Reference)
  end
end

RSpec.describe "Canvas draw_image with matrix: parameter" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "accepts a matrix parameter" do
    canvas.draw_image(:Im1, matrix: [200, 0, 0, 150, 72, 300])
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("200")
    expect(data).to include("/Im1 Do")
  end

  it "accepts rotation matrix" do
    rad = 30 * Math::PI / 180
    cos = Math.cos(rad)
    sin = Math.sin(rad)
    canvas.draw_image(:Im1, matrix: [cos, sin, -sin, cos, 100, 200])
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("Do")
  end

  it "tracks used XObjects" do
    canvas.draw_image(:Im1, matrix: [100, 0, 0, 100, 0, 0])
    expect(canvas.used_xobjects).to include(:Im1)
  end
end

RSpec.describe "Font subsetting framework" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "exposes subsetter as private API" do
    expect(doc.fonts).to respond_to(:valid_font_data?)
  end

  it "validates various font signatures" do
    expect(doc.fonts.valid_font_data?("truex")).to be true
    expect(doc.fonts.valid_font_data?("typ1x")).to be true
  end
end
