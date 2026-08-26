# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Font subsetting on write" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "subset_fonts! is called during write" do
    font = doc.fonts.add("Helvetica")
    doc.fonts.encode_text("Hi", font)

    # Should not raise — subset_fonts! handles standard fonts gracefully
    io = StringIO.new
    expect { doc.write(io: io) }.not_to raise_error
  end

  it "does not subset when no codepoints used" do
    font = doc.fonts.add("Helvetica")
    # No text drawn — used_codepoints is empty
    expect(doc.fonts.used_codepoints(font)).to be_empty

    io = StringIO.new
    doc.write(io: io)
    # Should complete without error
  end

  it "tracks font streams for TrueType fonts" do
    ttf_data = "\u0000\u0001\u0000\u0000#{"\x00" * 200}"
    io = StringIO.new(ttf_data)
    font = doc.fonts.add(io)

    # The font stream should be tracked internally
    streams = doc.fonts.instance_variable_get(:@font_streams)
    expect(streams).to have_key(font)
  end

  it "does not track standard fonts for subsetting" do
    font = doc.fonts.add("Courier")
    streams = doc.fonts.instance_variable_get(:@font_streams)
    expect(streams).not_to have_key(font)
  end
end

RSpec.describe "Multi-stop gradient support" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "creates 2-stop gradient with Type 2 function" do
    name = doc.shadings.add_axial(
      from: [0, 0], to: [100, 0],
      stops: [[0.0, [:rgb, 1, 0, 0]], [1.0, [:rgb, 0, 0, 1]]]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][name]
    shading = doc.object(ref)
    func_ref = shading[:Function]
    func = doc.object(func_ref)
    expect(func[:FunctionType]).to eq(2)
  end

  it "creates 3-stop gradient with Type 3 stitching function" do
    name = doc.shadings.add_axial(
      from: [0, 0], to: [100, 0],
      stops: [
        [0.0, [:rgb, 1, 0, 0]],
        [0.5, [:rgb, 0, 1, 0]],
        [1.0, [:rgb, 0, 0, 1]],
      ]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][name]
    shading = doc.object(ref)
    func_ref = shading[:Function]
    func = doc.object(func_ref)
    expect(func[:FunctionType]).to eq(3)
    expect(func[:Functions]).to be_an(Array)
    expect(func[:Functions].length).to eq(2)
    bounds = func[:Bounds].is_a?(Pdfrb::Model::PdfArray) ? func[:Bounds].value : func[:Bounds]
    expect(bounds).to eq([0.5])
  end

  it "creates 4-stop gradient with 3 sub-functions" do
    name = doc.shadings.add_axial(
      from: [0, 0], to: [100, 0],
      stops: [
        [0.0, [:rgb, 0, 0, 0]],
        [0.33, [:rgb, 1, 0, 0]],
        [0.66, [:rgb, 0, 1, 0]],
        [1.0, [:rgb, 0, 0, 1]],
      ]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][name]
    shading = doc.object(ref)
    func_ref = shading[:Function]
    func = doc.object(func_ref)
    expect(func[:FunctionType]).to eq(3)
    expect(func[:Functions].length).to eq(3)
    bounds = func[:Bounds].is_a?(Pdfrb::Model::PdfArray) ? func[:Bounds].value : func[:Bounds]
    expect(bounds.length).to eq(2)
  end

  it "multi-stop radial gradient" do
    name = doc.shadings.add_radial(
      from: [50, 50, 0], to: [50, 50, 100],
      stops: [
        [0.0, [:gray, 0]],
        [0.5, [:gray, 0.5]],
        [1.0, [:gray, 1]],
      ]
    )
    ref = doc.pages.pages_root.value[:Resources][:Shading][name]
    shading = doc.object(ref)
    func_ref = shading[:Function]
    func = doc.object(func_ref)
    expect(func[:FunctionType]).to eq(3)
  end
end
