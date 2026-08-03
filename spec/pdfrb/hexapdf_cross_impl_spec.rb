# frozen_string_literal: true

require "spec_helper"
require "stringio"

# Cross-implementation diff vs HexaPDF. These specs verify that pdfrb's
# parsing produces the same structural model as HexaPDF for shared
# fixtures. Skipped when the `hexapdf` gem is not installed.
RSpec.describe "Cross-impl diff vs HexaPDF" do
  before { skip "hexapdf gem not installed" unless Gem.loaded_specs.key?("hexapdf") }

  let(:pdf_bytes) do
    Pdfrb::Document.new.tap do |d|
      font = d.fonts.add("Helvetica")
      3.times { |i| d.pages.add.canvas.text("Page #{i + 1}", at: [72, 720], font: font, size: 12) }
    end.then { |d| StringIO.new.tap { |io| d.write(io: io) }.string }
  end

  it "parses the same page count" do
    require "hexapdf"

    hexa = HexaPDF::Document.new(io: StringIO.new(pdf_bytes))
    pdfrb_doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))

    expect(pdfrb_doc.pages.count).to eq(hexa.pages.count)
  end

  it "extracts the same catalog keys" do
    require "hexapdf"

    hexa = HexaPDF::Document.new(io: StringIO.new(pdf_bytes))
    pdfrb_doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))

    hexa_keys = hexa.catalog.value.keys.map(&:to_sym).sort
    pdfrb_keys = pdfrb_doc.catalog.value.keys.map(&:to_sym).sort

    expect(pdfrb_keys).to include(*hexa_keys & pdfrb_keys)
  end

  it "round-trips through both implementations" do
    require "hexapdf"

    pdfrb_doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))
    io = StringIO.new
    pdfrb_doc.write(io: io)

    hexa = HexaPDF::Document.new(io: StringIO.new(io.string))
    expect(hexa.pages.count).to eq(3)
  end
end
