# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "open3"
require "tmpdir"
require "fileutils"

RSpec.describe "pdfrb CLI" do
  let(:pdfrb_exe) { File.expand_path("../../exe/pdfrb", __dir__) }
  let(:tmpdir) { Dir.mktmpdir("pdfrb-cli-") }

  after { FileUtils.remove_entry(tmpdir) }

  def make_pdf(text: "Hello, CLI!", path:)
    doc = Pdfrb::Document.new
    doc.metadata.title = "Test PDF"
    doc.metadata.author = "RSpec"
    font = doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text(text, at: [72, 720], font: font, size: 24)
    doc.write(path)
  end

  def run_cli(*args)
    stdout, status = Open3.capture2("bundle", "exec", "ruby", pdfrb_exe, *args)
    [stdout, status]
  end

  it "prints version" do
    out, status = run_cli("version")
    expect(status.success?).to be(true)
    expect(out).to match(/\Apdfrb \d+\.\d+\.\d+/)
  end

  it "info prints metadata and page count" do
    path = File.join(tmpdir, "a.pdf")
    make_pdf(path: path)
    out, status = run_cli("info", path)
    expect(status.success?).to be(true)
    expect(out).to include("Pages: 1")
    expect(out).to include("Title: Test PDF")
    expect(out).to include("Author: RSpec")
  end

  it "extract-text prints per-page text" do
    path = File.join(tmpdir, "a.pdf")
    make_pdf(text: "Hello, CLI!", path: path)
    out, status = run_cli("extract-text", path)
    expect(status.success?).to be(true)
    expect(out).to include("Hello, CLI!")
  end

  it "merge concatenates two PDFs" do
    a = File.join(tmpdir, "a.pdf")
    b = File.join(tmpdir, "b.pdf")
    out = File.join(tmpdir, "merged.pdf")
    make_pdf(text: "from A", path: a)
    make_pdf(text: "from B", path: b)

    _, status = run_cli("merge", out, a, b)
    expect(status.success?).to be(true)

    merged = Pdfrb::Document.open(out)
    expect(merged.pages.count).to eq(2)
  end

  it "images lists nothing for a text-only doc" do
    path = File.join(tmpdir, "a.pdf")
    make_pdf(path: path)
    out, status = run_cli("images", path)
    expect(status.success?).to be(true)
    expect(out.strip).to eq("")
  end
end
