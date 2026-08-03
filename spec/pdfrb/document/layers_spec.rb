# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Layers do
  let(:doc) do
    Pdfrb::Document.new.tap do |d|
      d.pages.add
    end
  end

  it "creates an OCG with a name" do
    layer = doc.layers.add("Background Art")

    expect(layer.value[:Type]).to eq(:OCG)
    expect(layer.value[:Name]).to eq("Background Art")
  end

  it "populates /OCProperties on catalog with all layers" do
    doc.layers.add("Layer A")
    doc.layers.add("Layer B")
    doc.layers.sync!

    ocp = doc.catalog.value[:OCProperties]
    expect(ocp[:OCGs].length).to eq(2)
  end

  it "defaults layers to ON unless specified" do
    doc.layers.add("Visible")
    doc.layers.add("Hidden", default_on: false)
    doc.layers.sync!

    ocp = doc.catalog.value[:OCProperties]
    off_list = ocp[:D][:OFF]
    expect(off_list.length).to eq(1)
  end

  it "omits /OFF when all layers are default-on" do
    doc.layers.add("A")
    doc.layers.add("B")
    doc.layers.sync!

    ocp = doc.catalog.value[:OCProperties]
    expect(ocp[:D][:BaseState]).to eq(:ON)
    expect(ocp[:D][:OFF]).to be_nil
  end

  it "round-trips through serialization" do
    doc.layers.add("Art", default_on: false)
    doc.layers.add("Text")
    doc.layers.sync!

    io = StringIO.new
    doc.write(io: io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    ocp = reparsed.catalog.value[:OCProperties]
    expect(ocp).not_to be_nil
    expect(ocp[:OCGs].length).to eq(2)
  end
end
