# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::MultiPageTableBox do
  def text_cell(text = "x")
    Pdfrb::Layout::TextBox.new(text: text, width: 100, height: 14)
  end

  it "produces a single fragment when the table fits" do
    rows = (0..2).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200])
    fragments = table.fragments(available_width: 200, first_page_height: 500,
                                later_page_height: 500)
    expect(fragments.length).to eq(1)
  end

  it "produces multiple fragments when the table overflows" do
    rows = (0..20).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200])
    fragments = table.fragments(available_width: 200, first_page_height: 50,
                                later_page_height: 50)
    expect(fragments.length).to be > 1
  end

  it "repeats header rows on each fragment" do
    header = [[text_cell("HEADER")]]
    body = (0..10).map { [text_cell("body")] }
    table = described_class.new(rows: header + body,
                                column_widths: [200],
                                header_row_count: 1)
    fragments = table.fragments(available_width: 200, first_page_height: 50,
                                later_page_height: 50)
    expect(fragments.length).to be > 1
    fragments.each do |frag|
      # The first row of every fragment should be the header.
      first_cell = frag.rows.first.first
      expect(first_cell.box.text).to eq("HEADER")
    end
  end

  it "fit? returns true when at least one fragment exists" do
    rows = (0..5).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200])
    expect(table.fit?(200, 50)).to be true
  end

  it "each_fragment yields fragments" do
    rows = (0..10).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200])
    table.fit?(200, 50)
    fragments = table.each_fragment.to_a
    expect(fragments).not_to be_empty
  end

  it "respects min_rows_per_page" do
    rows = (0..5).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200],
                                min_rows_per_page: 10)
    fragments = table.fragments(available_width: 200, first_page_height: 50,
                                later_page_height: 50)
    # With min 10 rows per page and only 6 rows total, we should get
    # a single fragment with all 6 rows.
    expect(fragments.length).to eq(1)
  end

  it "draws without raising" do
    rows = (0..5).map { [text_cell] }
    table = described_class.new(rows: rows, column_widths: [200])
    table.fit?(200, 100)
    doc = Pdfrb::Document.new
    page = doc.pages.add
    canvas = page.canvas
    expect { table.draw(canvas, 10, 700) }.not_to raise_error
  end
end
