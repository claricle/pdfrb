# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::Operator do
  it "registers every PDF content operator" do
    expected = %w[
      q Q cm BT ET
      m l c v y h re n
      S s f F f* B B* b b*
      Tc Tw Tz TL Tf Tr Ts
      Td TD Tm T*
      Tj TJ ' "
      g G rg RG k K cs CS sc SC scn SCN
      w J j M d ri i gs
      BMC BDC EMC MP DP
    ]
    missing = expected.reject { |n| described_class[n] }
    expect(missing).to eq([]), "missing operators: #{missing.inspect}"
  end

  it "yields subclasses of Base for every entry" do
    described_class.registry.each do |name, klass|
      expect(klass < Pdfrb::Content::Operator::Base).to be(true), "#{name} -> #{klass} not Base"
    end
  end
end

RSpec.describe "operator serialization" do
  let(:s) { Pdfrb::Serializer.new }

  def serialize(op_name, *operands)
    op = Pdfrb::Content::Operator[op_name]
    op.serialize(s, *operands)
  end

  it "serialises NoArg operators as just the keyword + newline" do
    expect(serialize("q")).to eq("q\n")
    expect(serialize("BT")).to eq("BT\n")
  end

  it "serialises operand operators" do
    expect(serialize("m", 100, 200)).to eq("100 200 m\n")
    expect(serialize("Tf", :F1, 12)).to eq("/F1 12 Tf\n")
    expect(serialize("rg", 1.0, 0.0, 0.5)).to eq("1 0 0.5 rg\n")
  end

  it "serialises cm with 6 numbers" do
    expect(serialize("cm", 1, 0, 0, 1, 50, 50)).to eq("1 0 0 1 50 50 cm\n")
  end

  it "serialises re (rectangle)" do
    expect(serialize("re", 10, 20, 100, 200)).to eq("10 20 100 200 re\n")
  end

  it "serialises TJ with an array" do
    # Strings inside TJ are PDF text strings — they're wrapped in (...)
    # by the serializer, just like top-level strings.
    expect(serialize("TJ", ["He".b, -50, "llo".b])).to eq("[(He) -50 (llo)] TJ\n")
  end
end

RSpec.describe "operator invoke hooks" do
  let(:processor) { Pdfrb::Content::Processor.new }

  it "q/Q push and pop the graphics state" do
    initial = processor.graphics_state
    Pdfrb::Content::Operator::SaveGraphicsState.invoke(processor)
    Pdfrb::Content::Operator::LineWidth.invoke(processor, 5.0)
    expect(processor.graphics_state.line_width).to eq(5.0)
    Pdfrb::Content::Operator::RestoreGraphicsState.invoke(processor)
    expect(processor.graphics_state.line_width).to eq(1.0)
    expect(processor.graphics_state).to be(initial)
  end

  it "Tf updates the font in TextState" do
    Pdfrb::Content::Operator::Font.invoke(processor, :F1, 12.0)
    ts = processor.graphics_state.text_state
    expect(ts.font_name).to eq(:F1)
    expect(ts.font_size).to eq(12.0)
  end

  it "cm composes with the existing CTM" do
    Pdfrb::Content::Operator::ConcatMatrix.invoke(processor, 2, 0, 0, 2, 10, 10)
    expect(processor.graphics_state.ctm.transform_point(0, 0)).to eq([10.0, 10.0])
  end

  it "BT resets text + line matrices" do
    Pdfrb::Content::Operator::BeginText.invoke(processor)
    expect(processor.graphics_state.text_state.text_matrix).to be_identity
  end

  it "g/G set fill/stroke gray color" do
    Pdfrb::Content::Operator::FillGray.invoke(processor, 0.5)
    expect(processor.graphics_state.fill_color).to eq([:gray, 0.5])
    Pdfrb::Content::Operator::StrokeGray.invoke(processor, 0.25)
    expect(processor.graphics_state.stroke_color).to eq([:gray, 0.25])
  end

  it "BMC/EMC dispatch to hooks" do
    expect { Pdfrb::Content::Operator::BeginMarkedContent.invoke(processor, :Figure) }.not_to raise_error
    expect { Pdfrb::Content::Operator::EndMarkedContent.invoke(processor) }.not_to raise_error
  end
end
