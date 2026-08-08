# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::ImageLoader::PNG do
  describe ".parse_header" do
    it "parses a PNG IHDR chunk" do
      # PNG signature + IHDR chunk
      data = "\x89PNG\r\n\x1A\n".b # PNG signature
      data += "\x00\x00\x00\x0D".b # chunk length = 13
      data += "IHDR"
      data += [100].pack("N")  # width = 100
      data += [200].pack("N")  # height = 200
      data += "\x08".b          # 8 bits
      data += "\x02".b          # color type 2 = RGB
      data += "\x00\x00\x00".b  # compression, filter, interlace

      info = described_class.parse_header(data)
      expect(info[:width]).to eq(100)
      expect(info[:height]).to eq(200)
      expect(info[:bits]).to eq(8)
      expect(info[:color_space]).to eq(:DeviceRGB)
    end

    it "returns empty hash for non-PNG data" do
      expect(described_class.parse_header("not a png")).to eq({})
    end
  end

  describe "color-key masking (TODO 130)" do
    def build_png_with_trns(color_type:, trns_bytes:)
      data = +"\x89PNG\r\n\x1A\n".b
      data += "\x00\x00\x00\x0D".b # length 13
      data += "IHDR"
      data += [2].pack("N")  # width
      data += [2].pack("N")  # height
      data += "\x08".b       # bits
      data += color_type.chr
      data += "\x00\x00\x00".b
      data += "\x00\x00\x00\x00".b # IHDR CRC (fake but length-correct)
      unless trns_bytes.empty?
        data += [trns_bytes.bytesize].pack("N")
        data += "tRNS"
        data += trns_bytes
        data += "\x00\x00\x00\x00".b # CRC
      end
      data += "\x00\x00\x00\x00".b
      data += "IDAT"
      data += "\x00\x00\x00\x00".b # IEND length
      data += "IEND"
      data
    end

    it "emits /Mask array for grayscale PNG with tRNS" do
      info = described_class.parse_header(
        build_png_with_trns(color_type: 0, trns_bytes: [0, 128].pack("C*"))
      )
      mask = described_class.color_key_mask(info)
      expect(mask).to eq([128, 128]) # u16 of bytes 0,128
    end

    it "emits /Mask array for RGB PNG with tRNS" do
      info = described_class.parse_header(
        build_png_with_trns(color_type: 2,
                            trns_bytes: [0, 255, 0, 0, 0, 128].pack("C*"))
      )
      mask = described_class.color_key_mask(info)
      expect(mask).to eq([255, 255, 0, 0, 128, 128])
    end

    it "returns nil when tRNS is absent" do
      info = described_class.parse_header(
        build_png_with_trns(color_type: 2, trns_bytes: "")
      )
      expect(described_class.color_key_mask(info)).to be_nil
    end

    it "returns nil for indexed PNG (palette uses /SMask)" do
      info = described_class.parse_header(
        build_png_with_trns(color_type: 3, trns_bytes: "\xFF\x80".b)
      )
      expect(described_class.color_key_mask(info)).to be_nil
    end

    it "PNG image XObject includes /Mask when tRNS present" do
      doc = Pdfrb::Document.new
      png = build_png_with_trns(color_type: 2,
                                trns_bytes: [0, 255, 0, 0, 0, 128].pack("C*"))
      image = described_class.call(doc, png)
      expect(image.value[:Mask]).to eq([255, 255, 0, 0, 128, 128])
    end
  end
end
