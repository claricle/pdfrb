# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::ImageLoader::JPEG do
  describe ".parse_header" do
    it "parses SOF0 marker" do
      data = "\xFF\xD8".b
      data += "\xFF\xC0\x00\x11\x08\x00\xC8\x00\x64\x03".b
      info = described_class.parse_header(data)
      expect(info[:width]).to eq(100)
      expect(info[:height]).to eq(200)
    end

    it "returns empty hash for non-JPEG" do
      expect(described_class.parse_header("not jpeg")).to eq({})
    end
  end

  describe ".call" do
    it "returns nil for non-JPEG bytes" do
      doc = Pdfrb::Document.new
      expect(described_class.call(doc, "not a jpeg".b)).to be_nil
    end
  end
end
