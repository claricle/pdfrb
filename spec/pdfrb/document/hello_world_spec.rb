# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tmpdir"
require "fileutils"

# The "Hello World" milestone. A user should be able to create a PDF
# with text on a page in three lines:
#
#   doc = Pdfrb::Document.new
#   page = doc.pages.add
#   page.canvas.text("Hello", at: [72, 720], font: doc.fonts.add("Helvetica"), size: 24)
#   doc.write("/tmp/hello.pdf")
RSpec.describe "Document facade end-to-end" do
  let(:tmpdir) { Dir.mktmpdir("pdfrb-facade-") }

  after { FileUtils.remove_entry(tmpdir) }

  it "creates a single-page PDF with text and round-trips it" do
    src = Pdfrb::Document.new
    src.metadata.title = "Test PDF"
    font = src.fonts.add("Helvetica")
    page = src.pages.add
    page.canvas.text("Hello, Pdfrb!", at: [72, 720], font: font, size: 24)
    page.canvas.fill_color([:rgb, 0, 0, 1]).rectangle(72, 600, 200, 50).stroke

    out = StringIO.new
    src.write(io: out)

    # Re-read and verify.
    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.pages.count).to eq(1)
    dest_page = dest.pages[0]
    expect(dest_page[:Type]).to eq(:Page)
    contents = dest.object(dest_page.value[:Contents])
    payload = contents.decoded_stream
    expect(payload).to include("/F1 24 Tf")
    expect(payload).to include("(Hello, Pdfrb!) Tj")
    expect(payload).to include("0 0 1 rg")
    expect(payload).to include("72 600 200 50 re")
    expect(payload).to include("S")
  end

  it "write(path) round-trips" do
    path = File.join(tmpdir, "hello.pdf")
    src = Pdfrb::Document.new
    font = src.fonts.add("Times-Roman")
    src.pages.add.canvas.text("Times", at: [50, 700], font: font, size: 12)
    src.write(path)
    expect(File.size(path)).to be > 0

    dest = Pdfrb::Document.open(path)
    expect(dest.pages.count).to eq(1)
    expect(dest.metadata.title).to be_nil # title not set
  end

  it "supports multi-page documents" do
    src = Pdfrb::Document.new
    font = src.fonts.add("Courier")
    3.times do |i|
      src.pages.add.canvas.text("Page #{i + 1}", at: [50, 700], font: font, size: 12)
    end

    out = StringIO.new
    src.write(io: out)

    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.pages.count).to eq(3)
    pages = dest.pages.to_a
    expect(pages.length).to eq(3)
    pages.each_with_index do |page, i|
      payload = dest.object(page.value[:Contents]).decoded_stream
      expect(payload).to include("(Page #{i + 1}) Tj")
    end
  end

  it "writes metadata that round-trips through Info" do
    src = Pdfrb::Document.new
    src.metadata.title = "Round-Trip Title"
    src.metadata.author = "Pdfrb Author"

    out = StringIO.new
    src.write(io: out)

    dest = Pdfrb::Document.new(io: StringIO.new(out.string.b))
    expect(dest.metadata.title).to eq("Round-Trip Title")
    expect(dest.metadata.author).to eq("Pdfrb Author")
  end
end
