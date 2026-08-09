# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::TableBox do
  let(:doc) { Pdfrb::Document.new }

  def text_cell(text)
    Pdfrb::Layout::TextBox.new(text: text, width: 100, height: 20)
  end

  it "fits a simple 2x2 table" do
    table = described_class.new(rows: [
                                  [text_cell("A"), text_cell("B")],
                                  [text_cell("C"), text_cell("D")],
                                ])
    expect(table.fit?(200, 100)).to be true
    expect(table.row_heights.length).to eq(2)
  end

  it "accepts colspan via TableBox.cell" do
    cell = described_class.cell(text_cell("span"), colspan: 2)
    expect(cell.colspan).to eq(2)
    expect(cell.rowspan).to eq(1)
  end

  it "accepts rowspan via TableBox.cell" do
    cell = described_class.cell(text_cell("span"), rowspan: 2)
    expect(cell.rowspan).to eq(2)
  end

  it "accepts hash-form cells with colspan" do
    table = described_class.new(rows: [
                                  [{ box: text_cell("span"), colspan: 2 }],
                                  [text_cell("A"), text_cell("B")],
                                ])
    expect(table.fit?(200, 100)).to be true
  end

  it "honours colspan by giving the cell the combined column width" do
    span_cell = described_class.cell(text_cell("wide"), colspan: 2)
    table = described_class.new(rows: [
                                  [span_cell, text_cell("C")],
                                  [text_cell("A"), text_cell("B"), text_cell("C2")],
                                ], column_widths: [50, 50, 50])
    expect(table.fit?(150, 100)).to be true
  end

  it "honours rowspan by giving the cell the combined row height" do
    span_cell = described_class.cell(text_cell("tall"), rowspan: 2)
    table = described_class.new(rows: [
                                  [span_cell, text_cell("B")],
                                  [text_cell("C"), text_cell("D")],
                                ], column_widths: [50, 50])
    expect(table.fit?(100, 100)).to be true
  end

  it "draws without raising" do
    span_cell = described_class.cell(text_cell("span"), colspan: 2, rowspan: 2)
    table = described_class.new(rows: [
                                  [span_cell, text_cell("C")],
                                  [text_cell("D"), text_cell("E")],
                                ], column_widths: [50, 50])
    table.fit?(100, 100)
    page = doc.pages.add
    canvas = page.canvas
    expect { table.draw(canvas, 10, 700) }.not_to raise_error
  end

  it "is empty when rows are absent" do
    table = described_class.new(rows: [])
    expect(table).to be_empty
  end

  it "grid origin detection works for a 1x1 cell" do
    table = described_class.new(rows: [[text_cell("X")]], column_widths: [100])
    table.fit?(100, 50)
    expect(table.row_heights.first).to be_positive
  end
end
