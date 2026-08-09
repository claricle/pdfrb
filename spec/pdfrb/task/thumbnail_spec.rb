# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "zlib"

RSpec.describe Pdfrb::Task::Thumbnail do
  let(:doc) { Pdfrb::Document.new }

  it "generates a /Thumb on every page" do
    3.times { doc.pages.add }
    count = described_class.call(doc)
    expect(count).to eq(3)
    doc.pages.each do |page|
      expect(page.value[:Thumb]).to be_a(Pdfrb::Model::Reference)
    end
  end

  it "is idempotent when force is false" do
    doc.pages.add
    described_class.call(doc)
    first_thumb = doc.pages.first.value[:Thumb]
    described_class.call(doc)
    expect(doc.pages.first.value[:Thumb]).to eq(first_thumb)
  end

  it "replaces thumbnails when force is true" do
    doc.pages.add
    described_class.call(doc)
    first_thumb = doc.pages.first.value[:Thumb]
    described_class.call(doc, force: true)
    expect(doc.pages.first.value[:Thumb]).not_to eq(first_thumb)
  end

  it "thumbnail image is a valid FlateDecode image XObject" do
    doc.pages.add
    described_class.call(doc)
    thumb_ref = doc.pages.first.value[:Thumb]
    thumb = doc.object(thumb_ref)
    expect(thumb.value[:Type]).to eq(:XObject)
    expect(thumb.value[:Subtype]).to eq(:Image)
    expect(thumb.value[:Filter]).to eq(:FlateDecode)
    expect(thumb.value[:ColorSpace]).to eq(:DeviceGray)
    expect(thumb.stream).not_to be_empty
  end

  it "round-trips through serialization" do
    doc.pages.add
    described_class.call(doc)
    out = StringIO.new
    doc.write(io: out)
    reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
    thumb = reloaded.pages.first.value[:Thumb]
    expect(thumb).to be_a(Pdfrb::Model::Reference)
    thumb_obj = reloaded.object(thumb)
    expect(thumb_obj.value[:Subtype]).to eq(:Image)
  end

  it "page_pixel_dimensions respects max_width" do
    dims = described_class.page_pixel_dimensions([0, 0, 612, 792], 72, 100)
    expect(dims[0]).to be <= 100
  end

  it "page_pixel_dimensions returns [0, 0] for degenerate media box" do
    expect(described_class.page_pixel_dimensions([0, 0, 0, 0], 72, 100)).to eq([0, 0])
  end
end
