# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Proposal enhancement: Pages#add width/height" do
  it "accepts width: and height: as shorthand for media_box" do
    doc = Pdfrb::Document.new
    page = doc.pages.add(width: 595, height: 842)
    expect(page.value[:MediaBox]).to eq([0, 0, 595, 842])
  end

  it "media_box: takes precedence over width:/height:" do
    doc = Pdfrb::Document.new
    page = doc.pages.add(width: 100, height: 100, media_box: [0, 0, 200, 200])
    expect(page.value[:MediaBox]).to eq([0, 0, 200, 200])
  end

  it "defaults to US Letter when no dimensions given" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    expect(page.value[:MediaBox]).to eq([0, 0, 612, 792])
  end

  it "A4 page via width/height" do
    doc = Pdfrb::Document.new
    page = doc.pages.add(width: 595, height: 842)
    expect(page.media_box).to eq([0, 0, 595, 842])
  end
end

RSpec.describe "Proposal enhancement: Structure add_element with page/mcid" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "accepts page: and mcid: params" do
    doc.structure.enable!
    page = doc.pages.first
    elem = doc.structure.add_element(:H1, page: page, mcid: 0, title: "Title")
    expect(elem.value[:Pg]).to be_a(Pdfrb::Model::Reference)
    expect(elem.value[:Pg].oid).to eq(page.oid)
    expect(elem.value[:K]).to eq({ MCID: 0 })
  end

  it "works without page:/mcid: (backward compatible)" do
    doc.structure.enable!
    elem = doc.structure.add_element(:P, title: "Para")
    expect(elem.value[:Pg]).to be_nil
    expect(elem.value[:K]).to be_nil
  end

  it "builds ParentTree from page:/mcid: params" do
    doc.structure.enable!
    page = doc.pages.first
    doc.structure.add_element(:P, page: page, mcid: 0)
    doc.structure.add_element(:P, page: page, mcid: 1)

    doc.structure.build!
    pt = doc.structure.root.value[:ParentTree]
    expect(pt).not_to be_nil
    expect(pt[:Nums]).to include(0)
  end

  it "accepts page: as a Reference" do
    doc.structure.enable!
    page = doc.pages.first
    page_ref = Pdfrb::Model::Reference.new(page.oid, page.gen)
    elem = doc.structure.add_element(:Figure, page: page_ref, mcid: 2, alt: "Diagram")
    expect(elem.value[:Pg]).to eq(page_ref)
  end
end

RSpec.describe "Proposal enhancement: TrueType text measurement" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "falls back to heuristic for unknown fonts" do
    width = doc.fonts.text_width("Hello", "UnknownFont", size: 12)
    expect(width).to be_positive
  end

  it "measure_text works with registered standard fonts" do
    font = doc.fonts.add("Helvetica")
    width = doc.fonts.measure_text("Hello", font: font, size: 12)
    expect(width).to be_positive
    expect(width).to be_a(Float)
  end
end
