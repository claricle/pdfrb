# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"

RSpec.describe Pdfrb::Layout do
  describe Pdfrb::Layout::Frame do
    it "exposes bounding rectangle" do
      f = described_class.new(left: 50, bottom: 50, width: 500, height: 700)
      expect(f.left).to eq(50.0)
      expect(f.bottom).to eq(50.0)
      expect(f.width).to eq(500.0)
      expect(f.height).to eq(700.0)
      expect(f.right).to eq(550.0)
      expect(f.top).to eq(750.0)
    end

    it "finds available area for a fitting size" do
      f = described_class.new(left: 0, bottom: 0, width: 100, height: 100)
      pos = f.find_available_area(50, 30)
      expect(pos).to eq([0.0, 70.0, 50.0, 30.0])
    end

    it "returns nil when size doesn't fit" do
      f = described_class.new(left: 0, bottom: 0, width: 100, height: 100)
      expect(f.find_available_area(200, 50)).to be_nil
    end
  end

  describe Pdfrb::Layout::Style do
    it "loads presets" do
      s = described_class.new(:heading1)
      expect(s.font_name).to eq("Helvetica-Bold")
      expect(s.font_size).to eq(20)
    end

    it "merges overrides" do
      s = described_class.new(:base, font_size: 14)
      expect(s.font_size).to eq(14)
      expect(s.font_name).to eq("Helvetica")
    end

    it "is immutable — update returns new instance" do
      original = described_class.new(:base)
      updated = original.update(font_size: 24)
      expect(original.font_size).to eq(10)
      expect(updated.font_size).to eq(24)
    end

    it "serializes to hash" do
      s = described_class.new(:base)
      expect(s.to_h[:font_name]).to eq("Helvetica")
    end
  end

  describe Pdfrb::Layout::NumericRefinements do
    using described_class

    it "converts cm to pt" do
      expect(1.cm).to be_within(0.001).of(28.346)
    end

    it "converts mm to pt" do
      expect(10.mm).to be_within(0.001).of(28.346)
    end

    it "converts inch to pt" do
      expect(1.inch).to eq(72.0)
    end

    it "leaves pt as float" do
      expect(36.pt).to eq(36.0)
    end
  end

  describe Pdfrb::Layout::TextLayouter do
    it "breaks text into lines" do
      style = Pdfrb::Layout::Style.new(font_size: 10)
      layouter = described_class.new(style)
      lines = layouter.layout("Hello world this is a test", 50)
      expect(lines.length).to be > 1
      expect(lines).to all(be_a(Pdfrb::Layout::Line))
    end

    it "returns empty array for empty input" do
      layouter = described_class.new(Pdfrb::Layout::Style.new(:base))
      expect(layouter.layout("", 100)).to eq([])
    end
  end

  describe Pdfrb::Layout::Line do
    it "computes total width from fragments" do
      frag = Pdfrb::Layout::TextFragment.new(
        pieces: [["A", 0, 10]], style: Pdfrb::Layout::Style.new(:base),
        width: 10, height: 12, y_min: -2, y_max: 10
      )
      line = described_class.new(fragments: [frag, frag])
      expect(line.width).to eq(20)
      expect(line.height).to eq(12)
    end
  end

  describe Pdfrb::Layout::Box do
    it "has fit? returning true by default" do
      box = described_class.new
      expect(box.fit?(100, 100)).to be true
    end
  end

  describe Pdfrb::Layout::TextBox do
    it "fits when text fits available height" do
      style = Pdfrb::Layout::Style.new(font_size: 10)
      box = described_class.new(text: "Hello", style: style)
      expect(box.fit?(200, 100)).to be true
    end

    it "reports empty for blank text" do
      box = described_class.new(text: "", style: Pdfrb::Layout::Style.new(:base))
      expect(box.empty?).to be true
    end
  end

  describe Pdfrb::Layout::ContainerBox do
    it "fits when all children fit" do
      child1 = Pdfrb::Layout::TextBox.new(text: "A", style: Pdfrb::Layout::Style.new(:base))
      child2 = Pdfrb::Layout::TextBox.new(text: "B", style: Pdfrb::Layout::Style.new(:base))
      container = described_class.new(children: [child1, child2])
      expect(container.fit?(200, 1000)).to be true
    end
  end

  describe Pdfrb::Layout::PageStyle do
    it "computes dimensions for A4 portrait" do
      ps = described_class.new(name: :default)
      expect(ps.width).to be_within(0.01).of(595.28)
      expect(ps.height).to be_within(0.01).of(841.89)
    end

    it "swaps dimensions for landscape" do
      ps = described_class.new(name: :default, orientation: :landscape)
      expect(ps.width).to be_within(0.01).of(841.89)
    end

    it "builds a frame for content area" do
      ps = described_class.new(name: :default, margin: 50)
      frame = ps.frame
      expect(frame.left).to eq(50)
      expect(frame.bottom).to eq(50)
    end
  end

  describe Pdfrb::Layout::RomanNumeral do
    it "converts numbers to roman" do
      expect(described_class.convert(1)).to eq("I")
      expect(described_class.convert(4)).to eq("IV")
      expect(described_class.convert(9)).to eq("IX")
      expect(described_class.convert(2024)).to eq("MMXXIV")
    end

    it "returns 0 for non-positive" do
      expect(described_class.convert(0)).to eq("0")
      expect(described_class.convert(-1)).to eq("0")
    end
  end
end

RSpec.describe Pdfrb::Composer do
  it "creates a new document with one page" do
    c = described_class.new(skip_page_creation: false)
    expect(c.document.pages.count).to eq(1)
  end

  it "registers a style" do
    c = described_class.new(skip_page_creation: true)
    c.style(:h1, font_size: 24)
    expect(c.style?(:h1)).to be true
  end

  it "registers a page style" do
    c = described_class.new(skip_page_creation: true)
    c.page_style(:landscape, orientation: :landscape)
    expect(c.page_styles.key?(:landscape)).to be true
  end

  it "writes a PDF with text" do
    Tempfile.create(["composer", ".pdf"]) do |f|
      path = f.path
      f.close
      described_class.create(path) do |c|
        c.text("Hello, Composer!")
      end
      expect(File.exist?(path)).to be true
      bytes = File.binread(path)
      expect(bytes).to start_with("%PDF-")
    end
  end
end

RSpec.describe Pdfrb::TestUtils do
  it "creates a minimal document" do
    doc = described_class.minimal_document
    expect(doc).to be_a(Pdfrb::Document)
    expect(doc.pages.count).to eq(1)
  end

  it "creates minimal PDF bytes" do
    bytes = described_class.minimal_pdf
    expect(bytes).to start_with("%PDF-")
    expect(bytes).to end_with("%%EOF\n")
  end

  it "round-trips a document" do
    doc = described_class.minimal_document
    doc.metadata.title = "Test"
    reloaded = described_class.roundtrip(doc)
    expect(reloaded.metadata.title).to eq("Test")
  end

  it "counts pages" do
    bytes = described_class.minimal_pdf
    expect(described_class.count_pages(bytes)).to eq(1)
  end
end

RSpec.describe Pdfrb::Font::MetricsHelper do
  it "looks up Standard 14 metrics" do
    metrics = described_class.metrics_for("Helvetica")
    expect(metrics).not_to be_nil
    expect(metrics.units_per_em).to eq(1000)
    expect(metrics.ascent).to be_positive
  end

  it "computes line_height for a given font size" do
    metrics = described_class.metrics_for(:Helvetica)
    height = metrics.line_height(12)
    expect(height).to be_positive
  end
end

RSpec.describe Pdfrb::Document::GraphicsState do
  let(:doc) { Pdfrb::Document.new }
  let(:page) { doc.pages.add }

  it "registers an ExtGState with default params" do
    name = doc.graphics_state.register(page, CA: 0.5, ca: 0.5)
    expect(name).to match(/\AGS\d+\z/)
    resources = page.value[:Resources]
    expect(resources.value[:ExtGState][name]).to be_a(Pdfrb::Model::Reference)
  end

  it "registers transparency state" do
    name = doc.graphics_state.register_transparency(page, opacity: 0.5)
    expect(name).to match(/\AGS\d+\z/)
  end

  it "counts registered states" do
    doc.graphics_state.register(page, CA: 0.5)
    doc.graphics_state.register(page, LW: 2)
    expect(doc.graphics_state.count(page)).to eq(2)
  end
end
