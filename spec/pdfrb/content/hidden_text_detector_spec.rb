# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Content::HiddenTextDetector do
  let(:doc) { Pdfrb::Document.new }

  def build_content_stream(content_bytes)
    stream = doc.add(
      { Type: :XObject, Subtype: :Form, Length: content_bytes.bytesize },
      type: Pdfrb::Model::Cos::Stream
    )
    stream.stream = content_bytes
    stream
  end

  def add_form_to_page(page, form_stream)
    page.value[:Resources] ||= {}
    page.value[:Resources][:XObject] ||= {}
    page.value[:Resources][:XObject][:Fm1] =
      Pdfrb::Model::Reference.new(form_stream.oid, form_stream.gen)
  end

  it "reports no hidden text in visible content" do
    build_content_stream("BT /F1 12 Tf (Hello) Tj ET")
    detector = described_class.new(doc)

    hidden = detector.hidden_only
    expect(hidden).to be_empty
  end

  it "detects text rendered with Tr=3 (invisible rendering mode)" do
    build_content_stream("BT /F1 12 Tf 3 Tr (Hidden text) Tj ET")
    detector = described_class.new(doc)

    items = detector.detect.select(&:hidden?)
    expect(items.length).to eq(1)
    expect(items.first.text).to include("Hidden text")
    expect(items.first.reason).to eq(:rendering_mode_invisible)
  end

  it "detects text with ca=0 (fully transparent non-stroke)" do
    build_content_stream("BT /F1 12 Tf 0 ca (Transparent) Tj ET")
    detector = described_class.new(doc)

    items = detector.detect.select(&:hidden?)
    expect(items.length).to eq(1)
    expect(items.first.text).to include("Transparent")
    expect(items.first.reason).to eq(:alpha_zero_hidden)
  end

  it "detects text in TJ array (string-positioning operator)" do
    build_content_stream(
      "BT /F1 12 Tf 3 Tr [(First) -10 (Second) -10 (Third)] TJ ET"
    )
    detector = described_class.new(doc)

    items = detector.detect.select(&:hidden?)
    expect(items.length).to be >= 2
  end

  it "HiddenItem#hidden? is true only when reason is set" do
    item_hidden = described_class::HiddenItem.new(text: "x", reason: :rendering_mode_invisible)
    item_visible = described_class::HiddenItem.new(text: "y", reason: nil)

    expect(item_hidden.hidden?).to be true
    expect(item_visible.hidden?).to be false
  end

  it "handles empty documents gracefully" do
    detector = described_class.new(doc)
    expect { detector.detect }.not_to raise_error
    expect(detector.hidden_only).to eq([])
  end
end
