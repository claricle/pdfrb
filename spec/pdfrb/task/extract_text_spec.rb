# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Task::ExtractText do
  it "extracts text from a pdfrb-generated document" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hello, World!", at: [72, 720], font: font, size: 12)
    text = described_class.call(doc).first
    expect(text).to include("Hello")
    expect(text).to include("World")
  end

  it "extracts text from a multi-page document" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    3.times do |i|
      page = doc.pages.add
      page.canvas.text("Page #{i + 1} content here", at: [72, 720], font: font, size: 12)
    end
    texts = described_class.call(doc)
    expect(texts.length).to eq(3)
    expect(texts[0]).to include("Page 1")
    expect(texts[1]).to include("Page 2")
    expect(texts[2]).to include("Page 3")
  end

  it "handles documents without content gracefully" do
    doc = Pdfrb::Document.new
    doc.pages.add # empty page
    texts = described_class.call(doc)
    expect(texts.first).to eq("")
  end

  it "yields pages when block given" do
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hi", at: [72, 720], font: font, size: 12)
    pages_yielded = []
    described_class.call(doc) { |page, _text| pages_yielded << page }
    expect(pages_yielded.length).to eq(1)
  end
end
