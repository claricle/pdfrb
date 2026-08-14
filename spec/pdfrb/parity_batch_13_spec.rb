# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Parity batch 13 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Vri do
    it "exposes certificates, CRLs, OCSP responses" do
      cert_stream = doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      vri = doc.add(
        {
          Type: :VRI,
          Cert: [Pdfrb::Model::Reference.new(cert_stream.oid, 0)],
          CRL: [],
          OCSP: [],
        },
        type: described_class
      )
      expect(vri.type).to eq(:VRI)
      expect(vri.certificates(doc).length).to eq(1)
      expect(vri.crls(doc)).to eq([])
      expect(vri.ocsp_responses(doc)).to eq([])
    end

    it "round-trips through serialization" do
      doc.add({ Type: :VRI, Cert: [] }, type: described_class)
      out = StringIO.new
      doc.write(io: out)
      reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
      expect(reloaded.object(doc.trailer[:Root])).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::Thumbnail do
    it "exposes width, height, color space, bits" do
      thumb = doc.add(
        { Type: :XObject, Subtype: :Image, Width: 100, Height: 75,
          ColorSpace: :DeviceRGB, BitsPerComponent: 8, Filter: :FlateDecode,
          Length: 0 },
        type: described_class
      )
      thumb.stream = ""
      expect(thumb.width).to eq(100)
      expect(thumb.height).to eq(75)
      expect(thumb.color_space).to eq(:DeviceRGB)
      expect(thumb.bits_per_component).to eq(8)
      expect(thumb.dimensions).to eq([100, 75])
    end
  end

  describe Pdfrb::Model::Type::Timespan do
    it "exposes duration and milliseconds" do
      ts = doc.add({ Type: :Timespan, S: :S, V: 2.5 }, type: described_class)
      expect(ts.subtype).to eq(:S)
      expect(ts.duration).to eq(2.5)
      expect(ts.milliseconds).to eq(2500.0)
    end
  end

  describe Pdfrb::Model::Type::Viewport do
    it "exposes bbox, name, measure" do
      vp = doc.add({ Type: :Viewport, BBox: [0, 0, 100, 100], Name: "zoom" },
                   type: described_class)
      expect(vp.type).to eq(:Viewport)
      expect(vp.bbox).to eq([0, 0, 100, 100])
      expect(vp.name).to eq("zoom")
      expect(vp.measure(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::UserProperty do
    it "exposes name, value, format, hidden" do
      up = doc.add(
        { N: "Author", V: "Jane", F: "text", H: false },
        type: described_class
      )
      expect(up.name).to eq("Author")
      expect(up.property_value).to eq("Jane")
      expect(up.format).to eq("text")
      expect(up.hidden?).to be false
    end
  end
end
