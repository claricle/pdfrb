# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Model::Type::Resources do
  # Issue #64 regression coverage. resources.rb once failed to load with
  # a SyntaxError (a `.is_a?` without a receiver at the old line 61),
  # crashing every caller that triggered the type; `empty?` also only
  # recognised Arrays, never the Hashes a parsed document actually
  # carries. These specs pin the read path against real written and
  # re-parsed PDF bytes rather than synthetic hashes alone.

  def resources_from_doc
    doc = Pdfrb::Document.new
    doc.fonts.add("Helvetica")
    doc.pages.add.canvas.text("Hi", at: [10, 10], font: :F1, size: 12)

    io = StringIO.new
    doc.write(io: io)
    back = Pdfrb::Document.new(io: StringIO.new(io.string))

    raw = back.pages.first.value[:Resources] || {}
    described_class.new(raw)
  end

  def resources_from_doc_without_resources
    doc = Pdfrb::Document.new
    doc.pages.add

    io = StringIO.new
    doc.write(io: io)
    back = Pdfrb::Document.new(io: StringIO.new(io.string))

    raw = back.pages.first.value[:Resources] || {}
    described_class.new(raw)
  end

  it "loads and wraps resources parsed back from a written PDF" do
    resources = resources_from_doc
    expect(resources).not_to be_empty
    expect(resources.font_names).to include(:F1)
  end

  it "reports empty for a page written without resource entries" do
    expect(resources_from_doc_without_resources).to be_empty
  end

  it "reads named lookups from parsed bytes" do
    resources = resources_from_doc
    expect(resources.xobject_names).to eq([])
    expect(resources.has_procset?(:PDF)).to be(false)
  end

  it "empty? treats the Hash values a parser produces as empty or not" do
    parsed = { Font: { F1: :ref }, XObject: {}, ExtGState: {},
               ColorSpace: {}, Pattern: {}, Shading: {}, Properties: {} }
    resources = described_class.new(parsed)
    expect(resources).not_to be_empty

    resources = described_class.new(parsed.merge(Font: {}))
    expect(resources).to be_empty
  end
end
