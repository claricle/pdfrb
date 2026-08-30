# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Content::Canvas do
  let(:stream) { Pdfrb::Model::Cos::Stream.new({}, stream: "") }
  let(:canvas) { described_class.new(stream) }

  it "emits a moveto + lineto + stroke sequence" do
    canvas.move_to(10, 10).line_to(100, 100).stroke
    expect(stream.stream).to include("10 10 m\n")
    expect(stream.stream).to include("100 100 l\n")
    expect(stream.stream).to include("S\n")
  end

  it "emits a rectangle path" do
    canvas.rectangle(0, 0, 100, 100).fill
    expect(stream.stream).to include("0 0 100 100 re\n")
    expect(stream.stream).to include("f\n")
  end

  it "emits a text sequence via text(...)" do
    canvas.text("Hi", at: [50, 700], font: :F1, size: 12)
    expect(stream.stream).to include("BT\n")
    expect(stream.stream).to include("1 0 0 1 50 700 Tm\n")
    expect(stream.stream).to include("/F1 12 Tf\n")
    expect(stream.stream).to include("(Hi) Tj\n")
    expect(stream.stream).to include("ET\n")
  end

  it "supports save/restore via block" do
    canvas.save_graphics_state do |c|
      c.line_width = 5.0
    end
    expect(stream.stream).to include("q\n")
    expect(stream.stream).to include("5 w\n")
    expect(stream.stream).to include("Q\n")
  end

  it "emits a translate transform" do
    canvas.translate(100, 200)
    expect(stream.stream).to include("1 0 0 1 100 200 cm\n")
  end

  describe "graphics-state balance" do
    def operator_counts(str)
      str.lines.filter_map { |l| l.split.last }.tally
    end

    it "block-form transforms restore the graphics state (q/Q balance)" do
      canvas.translate(10, 10) { |c| c.rectangle(0, 0, 5, 5) }
      canvas.scale(2) { |c| c.circle(1, 1, 1) }
      canvas.rotate(Math::PI / 2) { |c| c.line(0, 0, 1, 1) }
      canvas.concat(1, 0, 0, 1, 5, 5) { |c| c.polyline([[0, 0], [1, 1]]) }

      counts = operator_counts(stream.stream)
      expect(counts["q"]).to eq(4)
      expect(counts["Q"]).to eq(4)
    end

    it "scopes the block-form matrix inside the saved state" do
      canvas.translate(10, 20) { |c| c.line_width = 2 }
      expect(stream.stream).to eq("q\n1 0 0 1 10 20 cm\n2 w\nQ\n")
    end

    it "with_transparency restores the graphics state" do
      doc = Pdfrb::Document.new.tap { |d| d.pages.add }
      doc.pages.first.canvas.with_transparency(opacity: 0.5,
                                               blend_mode: :Multiply) do |c|
        c.rectangle(0, 0, 10, 10)
      end
      data = doc.resolve(doc.pages.first.value[:Contents]).stream
      counts = operator_counts(data)
      expect(counts["q"]).to eq(1)
      expect(counts["Q"]).to eq(1)
      expect(data).to start_with("q\n")
      expect(data).to end_with("Q\n")
    end

    it "XObjects are invoked inside a balanced saved state" do
      canvas.draw_image(:Im0, at: [10, 10], width: 100, height: 50)
      canvas.draw_image_matrix(:Im1, a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)
      canvas.draw_form_xobject(:Fx0, at: [5, 5])
      canvas.draw_image(:Im2, matrix: [1, 0, 0, 1, 0, 0])

      counts = operator_counts(stream.stream)
      expect(counts["q"]).to eq(4)
      expect(counts["Q"]).to eq(4)
      expect(counts["Do"]).to eq(4)
    end
  end

  it "draw_image without matrix translates then scales before /Do" do
    canvas.draw_image(:Im0, at: [10, 20], width: 100, height: 50)
    expect(stream.stream).to include("1 0 0 1 10 20 cm\n")
    expect(stream.stream).to include("100 0 0 50 0 0 cm\n")
    expect(stream.stream).to include("/Im0 Do\n")
  end

  it "draw_form_xobject with default position still translates" do
    canvas.draw_form_xobject(:Fx0)
    expect(stream.stream).to include("1 0 0 1 0 0 cm\n")
    expect(stream.stream).to include("/Fx0 Do\n")
  end

  it "emits RGB fill color" do
    canvas.fill_color([:rgb, 1, 0, 0])
    expect(stream.stream).to include("1 0 0 rg\n")
  end

  it "emits marked content via block" do
    canvas.marked_content(:Figure) do |c|
      c.rectangle(0, 0, 50, 50)
    end
    expect(stream.stream).to include("/Figure BMC\n")
    expect(stream.stream).to include("EMC\n")
  end

  describe "drawing primitives" do
    it "polyline connects points via moveto + lineto" do
      canvas.polyline([[0, 0], [10, 10], [20, 0]])
      expect(stream.stream).to include("0 0 m\n")
      expect(stream.stream).to include("10 10 l\n")
      expect(stream.stream).to include("20 0 l\n")
    end

    it "polygon closes the path" do
      canvas.polygon([[0, 0], [10, 0], [10, 10]])
      expect(stream.stream).to include("h\n")
    end

    it "arc emits moveto and at least one lineto" do
      canvas.arc(50, 50, 10, start_angle: 0, end_angle: Math::PI)
      expect(stream.stream).to include(" m\n")
      expect(stream.stream).to include(" l\n")
    end

    it "arc with zero span is a no-op" do
      canvas.arc(0, 0, 10, start_angle: 0.5, end_angle: 0.5)
      expect(stream.stream).to eq("")
    end

    it "circle closes the path" do
      canvas.circle(50, 50, 10)
      expect(stream.stream).to include("h\n")
    end

    it "ellipse produces a closed path" do
      canvas.ellipse(50, 50, 20, 10)
      expect(stream.stream).to include("h\n")
    end

    it "rounded_rectangle emits moveto and close" do
      canvas.rounded_rectangle(0, 0, 100, 50, 5)
      expect(stream.stream).to include(" m\n")
      expect(stream.stream).to include("h\n")
    end

    it "rounded_rectangle accepts 4-corner radii" do
      expect do
        canvas.rounded_rectangle(0, 0, 100, 50, [2, 4, 6, 8])
      end.not_to raise_error
    end

    it "dash= is an alias for dash_pattern=" do
      canvas.dash = [3, 2]
      expect(stream.stream).to include("[3 2] 0 d\n")
    end

    it "inline_image emits BI/ID/EI block" do
      canvas.inline_image(dict: { W: 2, H: 2, CS: :G, BPC: 8 },
                          data: "\x00\xFF\xFF\x00".b)
      out = stream.stream
      expect(out).to include("BI\n")
      expect(out).to include("/W 2")
      expect(out).to include("/H 2")
      expect(out).to include("/CS /G")
      expect(out).to include("/BPC 8")
      expect(out).to include("ID\n")
      expect(out).to include("EI\n")
    end
  end
end
