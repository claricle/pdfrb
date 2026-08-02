# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::Parser do
  def invocations(src)
    described_class.parse(src).each_invocation.to_a
  end

  it "parses a single no-arg operator" do
    list = invocations("q")
    expect(list.length).to eq(1)
    op, operands = list.first
    expect(op).to be(Pdfrb::Content::Operator::SaveGraphicsState)
    expect(operands).to eq([])
  end

  it "parses a path+paint sequence" do
    list = invocations("100 100 m 200 200 m S")
    expect(list.map { |op, _| op.name }).to eq(%w[m m S])
    expect(list[0][1]).to eq([100, 100])
    expect(list[2][1]).to eq([])
  end

  it "parses text with Tf, Tj, BT, ET" do
    list = invocations("BT /F1 12 Tf (Hello) Tj ET")
    expect(list.map { |op, _| op.name }).to eq(%w[BT Tf Tj ET])
    expect(list[1][1]).to eq([:F1, 12])
    expect(list[2][1]).to eq(["Hello".b])
  end

  it "parses TJ with a kerning array" do
    list = invocations("BT [(Hel)-50(lo)] TJ ET")
    expect(list[1][1]).to eq([["Hel".b, -50, "lo".b]])
  end

  it "parses re (rectangle) and fill" do
    list = invocations("10 20 100 200 re f")
    expect(list.map { |op, _| op.name }).to eq(%w[re f])
    expect(list[0][1]).to eq([10, 20, 100, 200])
  end

  it "parses color ops" do
    list = invocations("1 0 0 rg 0.5 G")
    expect(list[0][0].name).to eq("rg")
    expect(list[0][1]).to eq([1.0, 0.0, 0.0])
    expect(list[1][0].name).to eq("G")
    expect(list[1][1]).to eq([0.5])
  end
end

RSpec.describe Pdfrb::Content::Processor do
  let(:recorder) do
    Class.new(described_class) do
      attr_reader :events

      def initialize
        super
        @events = []
      end

      def paint_path(fill:, stroke:, close:, rule:)
        @events << [:paint_path, fill, stroke, close, rule]
      end

      def show_text(str)
        @events << [:show_text, str]
      end

      def show_text_array(arr)
        @events << [:show_text_array, arr]
      end

      def path_move_to(x, y)
        @events << [:move_to, x, y]
      end

      def path_line_to(x, y)
        @events << [:line_to, x, y]
      end
    end.new
  end

  it "walks a stream and dispatches operators" do
    recorder.process(<<~PDF)
      100 100 m 200 200 l S
      BT /F1 12 Tf (Hi) Tj ET
    PDF
    expect(recorder.events).to include(
      [:move_to, 100.0, 100.0],
      [:line_to, 200.0, 200.0],
      [:paint_path, false, true, false, :nonzero],
      [:show_text, "Hi".b]
    )
  end

  it "maintains a graphics-state stack via q/Q" do
    recorder.process("q 5 w Q")
    expect(recorder.graphics_state.line_width).to eq(1.0)
  end
end
