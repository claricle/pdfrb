# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::OutputIntents do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "adds an output intent to the catalog" do
    icc_stream = doc.add({ N: 3 }, type: Pdfrb::Model::Cos::Stream)
    ref = Pdfrb::Model::Reference.new(icc_stream.oid, icc_stream.gen)

    doc.output_intents.add(ref, identifier: "FOGRA39",
                                condition: "Coated FOGRA39",
                                registry: "http://www.color.org")
    intents = doc.catalog.value[:OutputIntents]
    expect(intents.length).to eq(1)
  end

  it "embeds ICC profile and creates output intent" do
    icc_header = "\x00" * 128
    icc_header[0, 4] = [128].pack("N")
    icc_header[8, 4] = [0x02100000].pack("N")
    icc_header[12, 4] = "mntr"
    icc_header[16, 4] = "CMYK"
    icc_header[36, 4] = "acsp"

    doc.output_intents.embed_icc(icc_header, identifier: "CGATS TR 001")
    expect(doc.output_intents.count).to eq(1)
  end

  it "enumerates output intents" do
    icc_stream = doc.add({ N: 3 }, type: Pdfrb::Model::Cos::Stream)
    ref = Pdfrb::Model::Reference.new(icc_stream.oid, icc_stream.gen)
    doc.output_intents.add(ref, identifier: "FOGRA39")

    count = 0
    doc.output_intents.each { count += 1 }
    expect(count).to eq(1)
  end

  it "round-trips through serialization" do
    icc_stream = doc.add({ N: 4 }, type: Pdfrb::Model::Cos::Stream)
    ref = Pdfrb::Model::Reference.new(icc_stream.oid, icc_stream.gen)
    doc.output_intents.add(ref, identifier: "FOGRA39",
                                subtype: :GTS_PDFX)

    io = StringIO.new
    doc.write(io: io)
    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    intents = reparsed.catalog.value[:OutputIntents]
    expect(intents).not_to be_nil
  end
end

RSpec.describe Pdfrb::Document do
  it "sets BleedBox, TrimBox, ArtBox on page creation" do
    doc = described_class.new
    page = doc.pages.add(
      media_box: [0, 0, 612, 792],
      bleed_box: [-3, -3, 615, 795],
      trim_box: [0, 0, 612, 792],
      art_box: [36, 36, 576, 756]
    )
    expect(page.value[:BleedBox]).to eq([-3, -3, 615, 795])
    expect(page.value[:TrimBox]).to eq([0, 0, 612, 792])
    expect(page.value[:ArtBox]).to eq([36, 36, 576, 756])
  end

  it "supports CropBox" do
    doc = described_class.new
    page = doc.pages.add(crop_box: [10, 10, 600, 780])
    expect(page.value[:CropBox]).to eq([10, 10, 600, 780])
  end
end

RSpec.describe Pdfrb::Document::PageLabels do
  let(:doc) { Pdfrb::Document.new.tap { |d| 5.times { d.pages.add } } }

  it "builds a number tree with roman then decimal" do
    doc.page_labels.style(:roman_lower, count: 3)
      .style(:decimal, start: 1)
    doc.page_labels.commit!

    page_labels = doc.catalog.value[:PageLabels]
    expect(page_labels[:Nums]).to eq([
                                       0, { S: :r },
                                       3, { S: :D }
                                     ])
  end

  it "supports prefixed page labels" do
    doc.page_labels.style(:decimal, prefix: "A-", start: 1)
    doc.page_labels.commit!

    nums = doc.catalog.value[:PageLabels][:Nums]
    expect(nums[1][:P]).to eq("A-")
  end

  it "handles uppercase roman" do
    doc.page_labels.style(:roman_upper, count: 2)
    doc.page_labels.commit!
    nums = doc.catalog.value[:PageLabels][:Nums]
    expect(nums[1][:S]).to eq(:R)
  end

  it "round-trips through serialization" do
    doc.page_labels.style(:roman_lower, count: 2)
      .style(:decimal)
    doc.page_labels.commit!

    io = StringIO.new
    doc.write(io: io)
    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    labels = reparsed.catalog.value[:PageLabels]
    expect(labels).not_to be_nil
  end
end

RSpec.describe Pdfrb::Content::Shading::Axial do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "creates an axial shading dictionary" do
    function = Pdfrb::Model::PdfArray.new([:DeviceRGB, 0, 0, 0, 1, 1, 1])
    shading = described_class.new(
      color_space: :DeviceRGB,
      start_point: [0, 0],
      end_point: [612, 792],
      function: function
    )
    dict = shading.to_dict
    expect(dict[:ShadingType]).to eq(2)
    expect(dict[:ColorSpace]).to eq(:DeviceRGB)
  end

  it "registers in page Resources" do
    function = { FunctionType: 2, Domain: [0, 1], C0: [0, 0, 0], C1: [1, 1, 1], N: 1 }
    shading = described_class.new(
      color_space: :DeviceRGB,
      start_point: [0, 0],
      end_point: [100, 100],
      function: function
    )
    name = shading.register_on(doc, doc.pages.first)
    expect(name).to match(/\ASh\d+\z/)

    shading_dict = doc.pages.first.value[:Resources].value[:Shading]
    expect(shading_dict[name]).to be_a(Pdfrb::Model::Reference)
  end
end

RSpec.describe Pdfrb::Content::Shading::Radial do
  it "creates a radial shading dictionary" do
    function = { FunctionType: 2, Domain: [0, 1] }
    shading = described_class.new(
      color_space: :DeviceGray,
      center1: [0, 0], radius1: 0,
      center2: [50, 50], radius2: 100,
      function: function
    )
    dict = shading.to_dict
    expect(dict[:ShadingType]).to eq(3)
    expect(dict[:Coords].value).to eq([0, 0, 0, 50, 50, 100])
  end
end

RSpec.describe Pdfrb::Conformance::PdfX do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }

  it "registers X-1a, X-3, X-4 profiles" do
    expect(described_class.profiles.keys).to include(:x1a, :x3, :x4)
  end

  it "requires output intent" do
    result = described_class.validate(doc, level: :x4)
    v = result.violations.find { |x| x.rule_id == "px-1" }
    expect(v).not_to be_nil
  end

  it "requires TrimBox on pages" do
    result = described_class.validate(doc, level: :x4)
    v = result.violations.find { |x| x.rule_id == "px-2" }
    expect(v).not_to be_nil
  end

  it "prohibits encryption" do
    doc.instance_variable_set(:@trailer, { Encrypt: "yes" })
    result = described_class.validate(doc, level: :x4)
    v = result.violations.find { |x| x.rule_id == "px-4" }
    expect(v).not_to be_nil
  end

  it "passes when output intent and trim box present" do
    doc2 = Pdfrb::Document.new
    doc2.pages.add(trim_box: [0, 0, 612, 792])
    icc_stream = doc2.add({ N: 4 }, type: Pdfrb::Model::Cos::Stream)
    ref = Pdfrb::Model::Reference.new(icc_stream.oid, icc_stream.gen)
    doc2.output_intents.add(ref, identifier: "FOGRA39", subtype: :GTS_PDFX)
    doc2.instance_variable_set(:@trailer, { Info: doc2.add({ Trapped: :Unknown }) })

    result = described_class.validate(doc2, level: :x4)
    px1 = result.violations.find { |x| x.rule_id == "px-1" }
    px2 = result.violations.find { |x| x.rule_id == "px-2" }
    expect(px1).to be_nil
    expect(px2).to be_nil
  end

  it "X-1a flags RGB color spaces" do
    doc3 = Pdfrb::Document.new
    doc3.pages.add(trim_box: [0, 0, 612, 792])
    doc3.add({ ColorSpace: :DeviceRGB },
             type: Pdfrb::Model::Cos::Dictionary)

    result = described_class.validate(doc3, level: :x1a)
    rgb_v = result.violations.find { |x| x.rule_id == "x1a-1" }
    expect(rgb_v).not_to be_nil
  end

  it "uses rule registry (OCP)" do
    expect(described_class::SHARED.rules.length).to be >= 5
  end
end
