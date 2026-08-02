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
end
