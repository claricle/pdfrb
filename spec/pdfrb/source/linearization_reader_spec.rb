# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Source::LinearizationReader do
  it "returns nil for a non-linearized PDF" do
    src = Pdfrb::Document.new
    src.pages.add
    out = StringIO.new
    src.write(io: out)

    expect(described_class.detect(StringIO.new(out.string))).to be_nil
  end

  it "returns nil for non-PDF input" do
    expect(described_class.detect(StringIO.new("hello world"))).to be_nil
  end

  it "parses a synthetic Linearization dict" do
    pdf = +"%PDF-1.7\n"
    pdf << "%\xE2\xE3\xCF\xD3\n"
    pdf << "1 0 obj\n"
    pdf << "<< /Linearized 1.0 /L 9999 /O 2 /E 100 /N 3 /T 200 /H [250 50] >>\n"
    pdf << "endobj\n"

    info = described_class.detect(StringIO.new(pdf))
    expect(info).not_to be_nil
    expect(info.linearized).to eq("1.0")
    expect(info.page_count).to eq(3)
    expect(info.first_page_obj_offset).to eq(2)
    expect(info.primary_hint_offset).to eq([250, 50])
  end

  it "tolerates a Linearization dict missing optional fields" do
    pdf = +"%PDF-1.7\n"
    pdf << "%\xE2\xE3\xCF\xD3\n"
    pdf << "1 0 obj\n"
    pdf << "<< /Linearized 1 /L 1000 >>\n"
    pdf << "endobj\n"

    info = described_class.detect(StringIO.new(pdf))
    expect(info).not_to be_nil
    expect(info.linearized).to eq("1")
    expect(info.page_count).to be_nil
  end
end
