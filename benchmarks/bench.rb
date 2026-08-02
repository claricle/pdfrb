#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark script. Run with: bundle exec ruby benchmarks/bench.rb
# Compares pdfrb parse/serialize performance against HexaPDF (if installed).

require "bundler/setup"
require "pdfrb"
require "benchmark"
require "stringio"

def generate_test_pdf(pages: 10)
  doc = Pdfrb::Document.new
  font = doc.fonts.add("Helvetica")
  pages.times do |i|
    page = doc.pages.add
    page.canvas.text("Page #{i + 1} — the quick brown fox", at: [72, 720], font: font, size: 12)
  end
  out = StringIO.new
  doc.write(io: out)
  out.string
end

pdf_bytes = generate_test_pdf(pages: 10)
puts "Test PDF: #{pdf_bytes.bytesize} bytes, 10 pages"
puts

n = 100
Benchmark.bm(25) do |x|
  x.report("parse (x#{n})") do
    n.times { Pdfrb::Document.new(io: StringIO.new(pdf_bytes)) }
  end
  x.report("serialize (x#{n})") do
    n.times do
      doc = Pdfrb::Document.new
      font = doc.fonts.add("Helvetica")
      doc.pages.add.canvas.text("bench", at: [72, 720], font: font, size: 12)
      out = StringIO.new
      doc.write(io: out)
    end
  end
  x.report("round-trip (x#{n})") do
    n.times do
      doc = Pdfrb::Document.new(io: StringIO.new(pdf_bytes))
      out = StringIO.new
      doc.write(io: out)
    end
  end
end
