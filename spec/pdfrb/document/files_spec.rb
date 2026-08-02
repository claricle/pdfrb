# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document::Files do
  let(:doc) { Pdfrb::Document.new }

  describe "#add" do
    it "embeds a file and returns a FileSpec dict" do
      spec = doc.files.add("hello world", name: "test.txt")

      expect(spec).to be_a(Pdfrb::Model::Cos::Dictionary)
      expect(spec[:Type]).to eq(:FileSpec)
      expect(spec[:UF]).to eq("test.txt")
      expect(spec[:F]).to eq("test.txt")
    end

    it "creates an EmbeddedFile stream with the data" do
      spec = doc.files.add("hello world", name: "test.txt")
      ef_ref = spec[:EF][:UF]
      ef = doc.object(ef_ref)

      expect(ef).to be_a(Pdfrb::Model::Cos::Stream)
      expect(ef[:Type]).to eq(:EmbeddedFile)
      expect(ef.stream).to eq("hello world")
    end

    it "accepts a MIME type" do
      spec = doc.files.add("data", name: "f.csv", mime_type: "text/csv")
      ef = doc.object(spec[:EF][:UF])
      expect(ef[:Subtype]).to eq("text/csv")
    end

    it "accepts a description" do
      spec = doc.files.add("data", name: "f.txt", description: "A test file")
      expect(spec[:Desc]).to eq("A test file")
    end

    it "accepts an IO object" do
      io = StringIO.new("from io")
      spec = doc.files.add(io, name: "io.txt")
      ef = doc.object(spec[:EF][:UF])
      expect(ef.stream).to eq("from io")
    end
  end

  describe "#each" do
    it "yields embedded files" do
      doc.files.add("data1", name: "a.txt")
      doc.files.add("data2", name: "b.txt")

      results = doc.files.to_a
      expect(results.length).to eq(2)
      expect(results[0][0]).to eq("a.txt")
      expect(results[1][0]).to eq("b.txt")
    end

    it "returns empty when no files embedded" do
      expect(doc.files.to_a).to be_empty
    end
  end

  describe "#[]" do
    it "retrieves a file by name" do
      doc.files.add("secret", name: "passwords.txt")
      spec = doc.files["passwords.txt"]

      expect(spec[:Type]).to eq(:FileSpec)
      ef = doc.object(spec[:EF][:UF])
      expect(ef.stream).to eq("secret")
    end

    it "returns nil for unknown name" do
      expect(doc.files["missing.txt"]).to be_nil
    end
  end

  describe "round-trip" do
    it "survives write + read" do
      doc.files.add("round-trip data", name: "rt.bin",
                                       mime_type: "application/octet-stream")

      out = StringIO.new
      doc.write(io: out)

      reloaded = Pdfrb::Document.new(io: StringIO.new(out.string))
      spec = reloaded.files["rt.bin"]
      expect(spec).not_to be_nil
      ef = reloaded.object(spec[:EF][:UF])
      expect(ef.stream).to eq("round-trip data")
    end
  end

  describe "#count and #empty?" do
    it "tracks count correctly" do
      expect(doc.files).to be_empty
      doc.files.add("d1", name: "a.txt")
      doc.files.add("d2", name: "b.txt")
      expect(doc.files.count).to eq(2)
      expect(doc.files).not_to be_empty
    end
  end
end
