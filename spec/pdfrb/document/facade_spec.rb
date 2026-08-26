# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Pages do
  let(:doc) { Pdfrb::Document.new }

  it "adds a page and tracks the count" do
    expect(doc.pages.count).to eq(0)
    page = doc.pages.add
    expect(page).to be_a(Pdfrb::Model::Type::Page)
    expect(doc.pages.count).to eq(1)
  end

  it "wires the page's /Parent to the pages tree root" do
    page = doc.pages.add
    parent = doc.object(page.value[:Parent])
    expect(parent[:Type]).to eq(:Pages)
  end

  it "exposes each page via iteration" do
    doc.pages.add
    doc.pages.add
    pages = doc.pages.to_a
    expect(pages.length).to eq(2)
    expect(pages.all? { |p| p.is_a?(Pdfrb::Model::Type::Page) }).to be(true)
  end

  it "supports indexed access" do
    first = doc.pages.add
    second = doc.pages.add
    expect(doc.pages[0].value).to eq(first.value)
    expect(doc.pages[1].value).to eq(second.value)
  end

  it "delete removes from the tree" do
    p1 = doc.pages.add
    doc.pages.delete(p1)
    expect(doc.pages.count).to eq(0)
  end

  it "seeds the Pages tree on first add when no Catalog /Pages" do
    page = doc.pages.add
    root = doc.object(doc.catalog.value[:Pages])
    expect(root.value[:Type]).to eq(:Pages)
    expect(root.value[:Count]).to eq(1)
  end
end

RSpec.describe Pdfrb::Document::Fonts do
  let(:doc) { Pdfrb::Document.new }

  it "registers a standard font and returns a resource name" do
    name = doc.fonts.add("Helvetica")
    expect(name).to eq(:F1)
  end

  it "caches by font name" do
    a = doc.fonts.add("Helvetica")
    b = doc.fonts.add("Helvetica")
    expect(a).to be(b)
  end

  it "attaches the font to Catalog /Resources /Font" do
    name = doc.fonts.add("Helvetica")
    font_ref = doc.pages.pages_root.value[:Resources][:Font][name]
    font = doc.object(font_ref)
    expect(font[:Subtype]).to eq(:Type1)
    expect(font[:BaseFont]).to eq(:Helvetica)
  end

  it "supports all 14 standard fonts" do
    Pdfrb::Document::Fonts::STANDARDS.each do |name|
      expect { doc.fonts.add(name) }.not_to raise_error
    end
  end
end

RSpec.describe Pdfrb::Document::Metadata do
  let(:doc) { Pdfrb::Document.new }

  it "round-trips a title" do
    doc.metadata.title = "Hello, World"
    expect(doc.metadata.title).to eq("Hello, World")
  end

  it "round-trips an author" do
    doc.metadata.author = "Ribose Inc."
    expect(doc.metadata.author).to eq("Ribose Inc.")
  end

  it "reads via []" do
    doc.metadata[:Subject] = "test"
    expect(doc.metadata[:Subject]).to eq("test")
  end

  it "returns nil for unset fields" do
    expect(doc.metadata.keywords).to be_nil
  end
end
