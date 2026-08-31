# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "outline reading" do
  def outlined_document
    Pdfrb::Document.new.tap do |doc|
      doc.pages.add
      chapter = doc.outline.add("第一章", dest: :xyz)
      doc.outline.add("第二章", dest: :xyz)
      entry = Pdfrb::Document::OutlineEntry
      chapter.add_child(entry.new(title: "1.1 前書き", dest: :xyz))
      chapter.add_child(entry.new(title: "1.2 結果", dest: :xyz))
      doc.outline.build!
    end
  end

  def write_and_reopen(doc)
    io = StringIO.new
    doc.write(io: io)
    Pdfrb::Document.new(io: StringIO.new(io.string.b))
  end

  it "yields bookmark items depth-first with decoded titles" do
    reopened = write_and_reopen(outlined_document)

    items = reopened.outline.to_a
    expect(items.map(&:title)).to eq(["第一章", "1.1 前書き", "1.2 結果", "第二章"])
  end

  it "wraps items in the typed OutlineItem class" do
    reopened = write_and_reopen(outlined_document)

    items = reopened.outline.to_a
    expect(items).to all(be_a(Pdfrb::Model::Type::OutlineItem))
    expect(items.first.has_children?).to be(true)
    expect(items.last.has_children?).to be(false)
  end

  it "returns an Enumerator when blockless" do
    reopened = write_and_reopen(outlined_document)

    expect(reopened.outline.each).to be_a(Enumerator)
    expect(reopened.outline.each.count).to eq(4)
  end

  it "is empty for documents without an outline" do
    doc = Pdfrb::Document.new
    doc.pages.add

    reopened = write_and_reopen(doc)

    expect(reopened.outline.empty?).to be(true)
    expect(reopened.outline.to_a).to eq([])
  end

  it "reads outlines from an encrypted document" do
    doc = outlined_document
    doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: 256)
    io = StringIO.new
    doc.write(io: io)

    reopened = Pdfrb::Document.new(io: StringIO.new(io.string.b),
                                   config: { "encryption.password" => "s3cret" })

    expect(reopened.outline.to_a.map(&:title)).to eq(
      ["第一章", "1.1 前書き", "1.2 結果", "第二章"]
    )
  end
end
