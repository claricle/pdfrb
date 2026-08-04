# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::ImageLoader::PNG do
  describe ".parse_png_header" do
    it "parses a PNG IHDR chunk" do
      # PNG signature + IHDR chunk
      data = "\x89PNG\r\n\x1A\n".b  # PNG signature
      data += "\x00\x00\x00\x0D".b   # chunk length = 13
      data += "IHDR"
      data += [100].pack("N")  # width = 100
      data += [200].pack("N")  # height = 200
      data += "\x08".b          # 8 bits
      data += "\x02".b          # color type 2 = RGB
      data += "\x00\x00\x00".b  # compression, filter, interlace

      info = described_class.parse_png_header(data)
      expect(info[:width]).to eq(100)
      expect(info[:height]).to eq(200)
      expect(info[:bits]).to eq(8)
      expect(info[:color_space]).to eq(:DeviceRGB)
    end

    it "returns empty hash for non-PNG data" do
      expect(described_class.parse_png_header("not a png")).to eq({})
    end
  end
end
