# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Graphic objects" do
  let(:stream) { Pdfrb::Model::Cos::Stream.new({}, stream: "") }
  let(:canvas) { Pdfrb::Content::Canvas.new(stream) }

  describe Pdfrb::Content::GraphicObject::Arc do
    it "tessellates a full circle into 4 Bezier curves" do
      arc = described_class.new(cx: 100, cy: 100, radius: 50)
      arc.draw(canvas)
      payload = stream.stream
      # 1 moveto + 4 curve_to.
      expect(payload.scan(/ m\n/).length).to eq(1)
      expect(payload.scan(/ c\n/).length).to eq(4)
    end

    it "supports partial arcs" do
      arc = described_class.new(cx: 0, cy: 0, radius: 10, start_angle: 0, end_angle: 90)
      arc.draw(canvas)
      expect(stream.stream.scan(/ c\n/).length).to eq(1)
    end
  end

  describe Pdfrb::Content::GraphicObject::Polyline do
    it "emits one moveto + N-1 linetos" do
      poly = described_class.new([[0, 0], [10, 10], [20, 0]])
      poly.draw(canvas)
      expect(stream.stream.scan(/ m\n/).length).to eq(1)
      expect(stream.stream.scan(/ l\n/).length).to eq(2)
    end

    it "closes when closed: true" do
      described_class.new([[0, 0], [10, 0], [10, 10]], closed: true).draw(canvas)
      expect(stream.stream).to include("h\n")
    end
  end

  describe Pdfrb::Content::GraphicObject::Rectangle do
    it "emits a single re for sharp corners" do
      described_class.new(x: 0, y: 0, width: 100, height: 50).draw(canvas)
      expect(stream.stream).to include("0 0 100 50 re\n")
    end

    it "emits 4 Bezier curves for rounded corners" do
      described_class.new(x: 0, y: 0, width: 100, height: 50, radius: 10).draw(canvas)
      expect(stream.stream.scan(/ c\n/).length).to eq(4)
    end
  end

  describe Pdfrb::Content::GraphicObject::Curve do
    it "emits a moveto + curve_to" do
      described_class.new(start: [0, 0], c1: [10, 20], c2: [30, 40],
                          endpoint: [50, 50]).draw(canvas)
      expect(stream.stream).to include("0 0 m\n")
      expect(stream.stream).to include("10 20 30 40 50 50 c\n")
    end
  end
end
