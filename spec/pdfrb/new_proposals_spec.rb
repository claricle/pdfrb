# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::Canvas do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "draws multiple lines with default leading" do
    canvas.text_lines(["Line 1", "Line 2", "Line 3"],
                      font: :F1, size: 12, at: [72, 720])
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("Line 1")
    expect(data).to include("Line 2")
    expect(data).to include("Line 3")
  end

  it "applies custom leading" do
    canvas.text_lines(["A", "B"], font: :F1, size: 10, at: [0, 100], leading: 20)
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    # Line B should be at y = 100 - 20 = 80
    expect(data).to include("80")
  end

  it "tracks font usage" do
    canvas.text_lines(["X"], font: :F1, size: 12, at: [0, 0])
    expect(canvas.used_fonts).to include(:F1)
  end

  it "handles empty lines array" do # rubocop:disable RSpec/NoExpectationExample
    canvas.text_lines([], font: :F1, size: 12, at: [0, 0])
    # Should not raise
  end
end

RSpec.describe Pdfrb::Document::Fonts do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "returns numeric width in font units" do
    font = doc.fonts.add("Helvetica")
    width = doc.fonts.glyph_width(font, "A".ord)
    expect(width).to be_positive
  end

  it "returns 0 for missing glyph" do
    font = doc.fonts.add("Helvetica")
    width = doc.fonts.glyph_width(font, 0xE000)
    expect(width).to eq(0)
  end

  it "glyph_widths returns array for multiple codepoints" do
    font = doc.fonts.add("Times-Roman")
    widths = doc.fonts.glyph_widths(font, "Hello".each_codepoint.to_a)
    expect(widths).to be_an(Array)
    expect(widths.length).to eq(5)
    expect(widths).to all(be_positive)
  end

  it "widths are unscaled (font units, not points)" do
    font = doc.fonts.add("Helvetica")
    w = doc.fonts.glyph_width(font, "A".ord)
    scaled = doc.fonts.measure_text("A", font: font, size: 1000)
    expect(scaled).to be_within(1.0).of(w.to_f)
  end
end

RSpec.describe Pdfrb::FontResolver do
  it "has default search paths" do
    resolver = described_class.new
    expect(resolver.search_paths).to include("/System/Library/Fonts")
  end

  it "accepts custom search paths" do
    resolver = described_class.new(search_paths: ["/tmp/fonts"])
    expect(resolver.search_paths).to eq(["/tmp/fonts"])
  end

  it "available_fonts returns array" do
    resolver = described_class.new(search_paths: [])
    expect(resolver.available_fonts).to eq([])
  end

  it "find returns nil for non-existent font" do
    resolver = described_class.new(search_paths: [])
    expect(resolver.find(family: "NonExistent")).to be_nil
  end

  it "find_by_ps_name returns nil when not found" do
    resolver = described_class.new(search_paths: [])
    expect(resolver.find_by_ps_name("NonExistentFont")).to be_nil
  end
end

RSpec.describe Pdfrb::Document::Shadings do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "creates an axial gradient" do
    name = doc.shadings.add_axial(
      from: [0, 0], to: [200, 0],
      stops: [[0.0, [:rgb, 1, 0, 0]], [1.0, [:rgb, 0, 0, 1]]]
    )
    expect(name).to match(/\ASh\d+\z/)
    expect(doc.shadings[name]).not_to be_nil
  end

  it "creates a radial gradient" do
    name = doc.shadings.add_radial(
      from: [50, 50, 0], to: [50, 50, 100],
      stops: [[0.0, [:rgb, 1, 0, 0]], [1.0, [:rgb, 0, 0, 1]]]
    )
    expect(name).to match(/\ASh\d+\z/)
  end

  it "registers in catalog Resources /Shading" do
    doc.shadings.add_axial(
      from: [0, 0], to: [100, 0],
      stops: [[0.0, [:gray, 0]], [1.0, [:gray, 1]]]
    )
    shading_dict = doc.pages.pages_root.value[:Resources][:Shading]
    expect(shading_dict[:Sh1]).to be_a(Pdfrb::Model::Reference)
  end

  it "shading dict has ShadingType 2 for axial" do
    doc.shadings.add_axial(
      from: [0, 0], to: [100, 0],
      stops: [[0.0, [:rgb, 0, 0, 0]], [1.0, [:rgb, 1, 1, 1]]]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][:Sh1]
    shading = doc.object(ref)
    expect(shading[:ShadingType]).to eq(2)
  end

  it "shading dict has ShadingType 3 for radial" do
    doc.shadings.add_radial(
      from: [0, 0, 0], to: [50, 50, 100],
      stops: [[0.0, [:rgb, 0, 0, 0]], [1.0, [:rgb, 1, 1, 1]]]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][:Sh1]
    shading = doc.object(ref)
    expect(shading[:ShadingType]).to eq(3)
  end
end

RSpec.describe Pdfrb::Content::Canvas, "#fill_shading" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  it "emits sh operator for shading fill" do
    canvas.fill_shading(:Sh1)
    stream = page.value[:Contents]
    stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
    data = stream_obj&.stream || ""
    expect(data).to include("/Sh1 sh")
  end
end

RSpec.describe "Font subsetting on write" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "tracks used codepoints for subsetting" do
    font = doc.fonts.add("Helvetica")
    doc.fonts.encode_text("Hello", font)
    used = doc.fonts.used_codepoints(font)
    expect(used).to include("H".ord, "e".ord, "l".ord, "o".ord)
  end

  it "used_codepoints is a Set" do
    font = doc.fonts.add("Helvetica")
    doc.fonts.encode_text("AB", font)
    used = doc.fonts.used_codepoints(font)
    expect(used).to be_a(Set)
  end

  it "accumulates codepoints across calls" do
    font = doc.fonts.add("Helvetica")
    doc.fonts.encode_text("AB", font)
    doc.fonts.encode_text("CD", font)
    used = doc.fonts.used_codepoints(font)
    expect(used.length).to eq(4)
  end
end
