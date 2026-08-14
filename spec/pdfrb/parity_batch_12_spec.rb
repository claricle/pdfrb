# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 12 specs" do
  describe Pdfrb::Layout::BoxFitter, "with fixed Frame" do
    let(:frame) { Pdfrb::Layout::Frame.new(left: 0, bottom: 0, width: 200, height: 600) }

    def make_box(w, h)
      Pdfrb::Layout::TextBox.new(text: "x", width: w, height: h)
    end

    it "places boxes sequentially without overlap" do
      boxes = [make_box(200, 50), make_box(200, 50), make_box(200, 50)]
      fitter = described_class.new(boxes: boxes, frame: frame)
      fitter.fit
      expect(fitter.result.length).to eq(3)
      ys = fitter.result.map { |_b, pos| pos[1] }
      expect(ys.sort).to eq(ys.reverse)
    end

    it "overflows when boxes exceed frame capacity" do
      boxes = Array.new(20) { make_box(200, 50) }
      fitter = described_class.new(boxes: boxes, frame: frame)
      fitter.fit
      expect(fitter.overflow).not_to be_empty
    end

    it "flows to a new frame when the first fills up" do
      boxes = Array.new(5) { make_box(200, 100) } # 5 * 100 = 500, fits in 600
      frame2 = nil
      fitter = described_class.new(boxes: boxes, frame: frame)
      fitter.fit do
        frame2 ||= Pdfrb::Layout::Frame.new(left: 0, bottom: 0, width: 200, height: 600)
      end
      expect(fitter.fit_complete?).to be true
    end

    it "draws all fitted boxes without raising" do
      doc = Pdfrb::Document.new
      page = doc.pages.add
      boxes = [make_box(200, 50), make_box(200, 50)]
      fitter = described_class.new(boxes: boxes, frame: frame)
      fitter.fit
      canvas = page.canvas
      expect { fitter.draw(canvas) }.not_to raise_error
    end
  end

  describe Pdfrb::Content::Processor, "inline image hook" do
    let(:stream) do
      (+"").b.tap do |s|
        s << "BI\n"
        s << "/W 1\n/H 1\n/CS /G\n/BPC 8\n"
        s << "ID\n"
        s << [128].pack("C")
        s << "\nEI\n"
      end
    end

    it "calls inline_image when BI/ID/EI is encountered" do
      processor = Class.new(described_class) do
        attr_reader :inline_seen

        def inline_image(image)
          @inline_seen = image
        end
      end.new

      processor.process(stream)
      expect(processor.inline_seen).not_to be_nil
      expect(processor.inline_seen[:header][:Width]).to eq(1)
      expect(processor.inline_seen[:header][:Height]).to eq(1)
    end

    it "does not crash on streams without inline images" do
      processor = described_class.new
      expect { processor.process("BT /F1 12 Tf (Hello) Tj ET\n") }.not_to raise_error
    end
  end

  describe Pdfrb::Layout::Frame, "BoxFitter integration" do
    it "cursor advances correctly after multiple removes" do
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 300)
      pos1 = frame.find_available_area(100, 100)
      frame.remove_area(pos1[0], pos1[1], 100, 100)
      expect(frame.cursor_y).to be <= 200.0

      pos2 = frame.find_available_area(100, 100)
      expect(pos2).not_to be_nil
      expect(pos2[1]).to be < pos1[1]
    end

    it "reset! clears all state for a fresh page" do
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 300)
      frame.find_available_area(100, 100)
      frame.remove_area(0, 100, 100, 200)
      expect(frame.empty?).to be false

      frame.reset!
      expect(frame.empty?).to be true
      expect(frame.available_height).to eq(300.0)
    end
  end
end
