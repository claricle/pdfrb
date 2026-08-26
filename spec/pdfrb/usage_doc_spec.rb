# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "stringio"

# Executes the code snippets documented in docs/USAGE.md so the
# cookbook cannot silently drift from the real API.
RSpec.describe "docs/USAGE.md cookbook" do
  let(:dir) { Dir.mktmpdir }

  def tmp(name)
    File.join(dir, name)
  end

  it "creating a PDF" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    page = doc.pages.add
    page.canvas.text("Hello, World!", at: [72, 720], font: font, size: 24)

    path = tmp("hello.pdf")
    doc.write(path)
    expect(File.binread(path)).to start_with("%PDF-")
    expect(Pdfrb.open(path).pages.count).to eq(1)
  end

  it "reading a PDF" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    2.times { |i| doc.pages.add.canvas.text("Page #{i}", at: [72, 720], font: font, size: 12) }
    path = tmp("read.pdf")
    doc.write(path)

    doc = Pdfrb.open(path)
    expect(doc.pages.count).to eq(2)
    texts = doc.pages.map { |page| Pdfrb::Task::ExtractText.call_single_page(page) }
    expect(texts.first).to include("Page 0")
    expect(texts.last).to include("Page 1")
  end

  it "drawing on a canvas" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    font = doc.fonts.add("Helvetica")

    page.canvas.tap do |c|
      c.text("Title", at: [72, 720], font: font, size: 18)
      c.rectangle(point: [72, 700], width: 200, height: 50)
      c.stroke
      c.line(from: [72, 600], to: [300, 600])
      c.stroke
    end

    path = tmp("drawing.pdf")
    doc.write(path)
    reopened = Pdfrb.open(path)
    content = reopened.pages.first.value[:Contents]
    expect(content).not_to be_nil
  end

  it "tagged PDF (accessibility)" do
    doc = Pdfrb::Document.new
    doc.structure.enable!
    doc.catalog.value[:Lang] = "en-US"

    doc_elem = doc.structure.add_element(:Document)
    doc.structure.add_child(doc_elem, :H1, title: "Introduction")
    doc.structure.add_child(doc_elem, :P)

    path = tmp("tagged.pdf")
    doc.write(path)
    reopened = Pdfrb.open(path)
    expect(reopened.catalog.value[:StructTreeRoot]).not_to be_nil
    expect(reopened.catalog.value[:Lang]).to eq("en-US")
  end

  it "optional content groups (layers)" do
    doc = Pdfrb::Document.new
    doc.layers.add("Background Art", default_on: false)
    doc.layers.add("Annotations")
    doc.layers.sync!

    path = tmp("layers.pdf")
    doc.write(path)
    reopened = Pdfrb.open(path)
    oc_props = reopened.catalog.value[:OCProperties]
    expect(oc_props).not_to be_nil
  end

  it "interactive forms (AcroForm)" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    doc.form.add_text_field("username", page: page, rect: [50, 700, 250, 720])
    doc.form.add_checkbox("agree", page: page, rect: [50, 650, 65, 665], checked: true)
    doc.form.add_combo("country", page: page, rect: [50, 600, 200, 620],
                                  options: %w[US UK JP], value: "US")

    path = tmp("form.pdf")
    doc.write(path)
    reopened = Pdfrb.open(path)
    acro = reopened.catalog.value[:AcroForm]
    expect(acro).not_to be_nil
  end

  it "semantic comparison (diff)" do
    left_doc = Pdfrb::Document.new
    left_doc.pages.add
    left = tmp("v1.pdf")
    left_doc.write(left)

    right_doc = Pdfrb::Document.new
    2.times { right_doc.pages.add }
    right = tmp("v2.pdf")
    right_doc.write(right)

    report = Pdfrb::Compare.compare(File.binread(left), File.binread(right))
    expect(report.page_count_delta).to eq(1)
    expect(report.equivalent?).to be false
  end

  it "merging PDFs" do
    target = Pdfrb::Document.new
    target.pages.add
    target_path = tmp("base.pdf")
    target.write(target_path)

    source = Pdfrb::Document.new
    2.times { source.pages.add }
    source_path = tmp("appendix.pdf")
    source.write(source_path)

    merged = Pdfrb.open(target_path)
    Pdfrb::Task::Merge.call(merged, Pdfrb.open(source_path))
    out = tmp("merged.pdf")
    merged.write(out)
    expect(Pdfrb.open(out).pages.count).to eq(3)
  end

  it "extracting images" do
    images = Pdfrb::Task::ExtractImages.call(Pdfrb.open(fixtures_path("simple-graphics.pdf")))
    expect(images).to be_an(Array)
  end

  it "encryption" do
    doc = Pdfrb::Document.new
    doc.pages.add
    encrypted = tmp("encrypted.pdf")
    doc.encrypt!(user_password: "secret", owner_password: "owner", bits: 128)
    doc.write(encrypted)
    expect(File.binread(encrypted)).to include("/Encrypt")

    reopened = Pdfrb.open(encrypted,
                          config: { "encryption.password" => "secret" })
    expect(reopened.pages.count).to eq(1)
  end

  it "Pdfrb.parse accepts bytes and IO" do
    doc = Pdfrb::Document.new
    doc.pages.add
    path = tmp("parse.pdf")
    doc.write(path)
    bytes = File.binread(path)

    expect(Pdfrb.parse(bytes).pages.count).to eq(1)
    expect(Pdfrb.parse(StringIO.new(bytes)).pages.count).to eq(1)
  end

  def fixtures_path(name)
    File.expand_path("../fixtures/pdf-core-examples/AnnexH-Examples/#{name}", __dir__)
  end
end
