# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Linearization::HintStream do
  it "encodes page-offset entries as packed bits" do
    hint = described_class.new(item_bits: 8)
    hint.add_page(offset_delta: 100, page_length: 200, num_objects: 3, page_obj_num: 5)

    data = hint.encode
    expect(data).to be_a(String)
    expect(data.encoding).to eq(Encoding::BINARY)
    expect(data).not_to be_empty
  end

  it "handles multiple pages" do
    hint = described_class.new
    hint.add_page(offset_delta: 0, page_length: 500, num_objects: 2, page_obj_num: 3)
    hint.add_page(offset_delta: 500, page_length: 600, num_objects: 2, page_obj_num: 10)

    data = hint.encode
    expect(data.bytesize).to be_positive
  end

  it "produces dictionary fields with correct item bits" do
    hint = described_class.new(item_bits: 16)
    fields = hint.dictionary_fields(42)
    expect(fields[:S]).to eq(16)
    expect(fields[:Length]).to eq(42)
  end
end

RSpec.describe Pdfrb::Linearization::Writer do
  let(:doc) do
    Pdfrb::Document.new.tap do |d|
      font = d.fonts.add("Helvetica")
      3.times do |i|
        d.pages.add.canvas.text("Page #{i + 1}", at: [72, 720], font: font, size: 12)
      end
    end
  end

  it "produces a valid PDF that starts with %PDF" do
    io = StringIO.new
    described_class.new(doc).write(io)

    expect(io.string).to start_with("%PDF-")
    expect(io.string).to include("%%EOF")
  end

  it "emits the /Linearized parameter dictionary" do
    io = StringIO.new
    described_class.new(doc).write(io)

    expect(io.string).to include("/Linearized")
  end

  it "is detected as linearized by Source::LinearizationDetection" do
    io = StringIO.new
    described_class.new(doc).write(io)

    read_io = StringIO.new(io.string)
    expect(Pdfrb::Source::LinearizationDetection.linearized?(read_io)).to be true
  end

  it "can be re-parsed by Pdfrb::Document" do
    io = StringIO.new
    described_class.new(doc).write(io)

    reparsed = Pdfrb::Document.new(io: StringIO.new(io.string))
    expect(reparsed.pages.count).to eq(3)
  end

  it "falls back to non-linearized for single-page docs" do
    single = Pdfrb::Document.new
    single.pages.add

    io = StringIO.new
    described_class.new(single).write(io)

    expect(io.string).to start_with("%PDF-")
  end

  describe "encrypted documents" do
    let(:encrypted_doc) do
      Pdfrb::Document.new.tap do |d|
        font = d.fonts.add("Helvetica")
        3.times do |i|
          d.pages.add.canvas.text("Hidden #{i + 1}",
                                  at: [72, 720], font: font, size: 12)
        end
        d.metadata[:Title] = "linsecret title"
        handler = Pdfrb::Encryption::StandardSecurityHandler
          .for_v5(user_password: "s3cret", owner_password: "s3cret")
        encrypt_dict = d.add(handler.encrypt_dict,
                             type: Pdfrb::Model::Cos::Dictionary)
        d.trailer[:Encrypt] = encrypt_dict.ref
        d.trailer[:ID] = ["id0id0id0id0id0".b, "id0id0id0id0id0".b]
        d.config["encryption.password"] = "s3cret"
      end
    end

    it "encrypts strings and stream payloads in the linearized output" do
      io = StringIO.new
      described_class.new(encrypted_doc).write(io)

      body = io.string
      expect(body).not_to include("linsecret title")
      expect(body).not_to include("Hidden 1")
    end

    it "carries /Encrypt and /ID in the trailer" do
      io = StringIO.new
      described_class.new(encrypted_doc).write(io)

      trailer = io.string[%r{trailer\n.*%%EOF}m]
      expect(trailer).to include("/Encrypt")
      expect(trailer).to include("/ID")
    end

    it "keeps the /Encrypt dictionary entries in cleartext" do
      io = StringIO.new
      described_class.new(encrypted_doc).write(io)

      expect(io.string).to include("/Filter /Standard")
    end
  end

  it "does not label the hint stream as /Type /XRef" do
    io = StringIO.new
    described_class.new(doc).write(io)

    hint = io.string[%r{/S \d+.*?stream}m]
    expect(hint).not_to include("/Type /XRef")
    expect(io.string.scan("/Type /XRef").count).to eq(0)
  end
end
