# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::ImageLoader::JPEG do
  describe ".parse_jpeg_header" do
    it "parses a minimal JPEG header" do
      # SOI + SOF0 (baseline) marker with width=100, height=200, 3 components
      data = "\xFF\xD8".b  # SOI
      data += "\xFF\xC0".b  # SOF0 marker
      data += "\x00\x11".b  # segment length (17 bytes)
      data += "\x08".b       # 8 bits
      data += "\x00\xC8".b   # height = 200
      data += "\x00\x64".b   # width = 100
      data += "\x03".b       # 3 components (RGB)

      info = described_class.parse_jpeg_header(data)
      expect(info[:width]).to eq(100)
      expect(info[:height]).to eq(200)
      expect(info[:bits]).to eq(8)
      expect(info[:color_space]).to eq(:DeviceRGB)
    end

    it "returns empty hash for non-JPEG data" do
      expect(described_class.parse_jpeg_header("not a jpeg")).to eq({})
    end
  end
end
