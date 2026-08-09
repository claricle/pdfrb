# frozen_string_literal: true

require "spec_helper"
require "zlib"

RSpec.describe "Parity batch 9 deep specs" do
  describe Pdfrb::ImageLoader::TIFF, "decode" do
    def build_uncompressed_tiff(width:, height:, spp: 3, photometric: 2)
      # Little-endian TIFF, single strip, no compression.
      data = +"II"
      data << [42].pack("S<")        # magic
      data << [0].pack("L<")         # IFD offset placeholder
      # IFD lives at offset 8 — patch the placeholder.
      ifd_offset = data.bytesize
      data[4, 4] = [ifd_offset].pack("L<")
      # Build image data first so we can reference its offset.
      # We'll append image data after the IFD.
      pixel_data = (0...height).map do |y|
        (0...width).map do |x|
          if spp == 3
            r = ((x * 17) + (y * 11)) % 256
            g = ((x * 23) + (y * 7)) % 256
            b = ((x * 31) + (y * 3)) % 256
            [r, g, b]
          else
            [(x + y) % 256]
          end
        end
      end.flatten
      pixel_bytes = pixel_data.pack("C*")

      # Construct IFD entries.
      num_entries = 9
      entries = +""
      entries << [num_entries].pack("S<")
      add_entry = lambda do |tag, type, count, value|
        entries << [tag, type, count].pack("S< S< L<")
        entries << if type == 3 # SHORT
                     if count == 1
                       [value, 0].pack("S< S<")
                     else
                       [value].pack("L<")
                     end
                   else
                     [value].pack("L<")
                   end
      end
      add_entry.call(256, 3, 1, width)   # ImageWidth
      add_entry.call(257, 3, 1, height)  # ImageLength
      add_entry.call(258, 3, 1, 8)       # BitsPerSample
      add_entry.call(259, 3, 1, 1)       # Compression (none)
      add_entry.call(262, 3, 1, photometric) # Photometric
      # StripOffsets (tag 273, type LONG) — placeholder; will patch.
      add_entry.call(273, 4, 1, 0)
      add_entry.call(278, 3, 1, height) # RowsPerStrip
      # StripByteCounts (tag 279, type LONG) — pixel bytes size.
      add_entry.call(279, 4, 1, pixel_bytes.bytesize)
      add_entry.call(277, 3, 1, spp) # SamplesPerPixel
      # Next IFD offset = 0 (no more IFDs).
      entries << [0].pack("L<")

      # Strip offset = current size + entries length.
      strip_offset = data.bytesize + entries.bytesize
      # Patch StripOffsets entry (it's the 7th entry, value field
      # is at offset 8 + 6*12 + 8 = 8 + 72 + 8 = 88 within the
      # IFD. Easier: re-encode the entries with the right value.
      # For simplicity, we rebuild entries with the correct strip_offset.
      entries = +""
      entries << [num_entries].pack("S<")
      add_entry.call(256, 3, 1, width)
      add_entry.call(257, 3, 1, height)
      add_entry.call(258, 3, 1, 8)
      add_entry.call(259, 3, 1, 1)
      add_entry.call(262, 3, 1, photometric)
      add_entry.call(273, 4, 1, strip_offset)
      add_entry.call(278, 3, 1, height)
      add_entry.call(279, 4, 1, pixel_bytes.bytesize)
      add_entry.call(277, 3, 1, spp)
      entries << [0].pack("L<")
      data << entries
      data << pixel_bytes
      data
    end

    it "decodes an uncompressed RGB TIFF" do
      data = build_uncompressed_tiff(width: 4, height: 4, spp: 3, photometric: 2)
      doc = Pdfrb::Document.new
      image = described_class.call(doc, data)
      expect(image).not_to be_nil
      expect(image.value[:Width]).to eq(4)
      expect(image.value[:Height]).to eq(4)
      expect(image.value[:ColorSpace]).to eq(:DeviceRGB)
      expect(image.value[:Filter]).to eq(:FlateDecode)
      # Decoded pixels are FlateDecode-compressed in the stream.
      decoded = Zlib.inflate(image.stream)
      expect(decoded.bytesize).to eq(4 * 4 * 3)
    end

    it "decodes an uncompressed grayscale TIFF" do
      data = build_uncompressed_tiff(width: 3, height: 3, spp: 1, photometric: 1)
      doc = Pdfrb::Document.new
      image = described_class.call(doc, data)
      expect(image.value[:ColorSpace]).to eq(:DeviceGray)
      decoded = Zlib.inflate(image.stream)
      expect(decoded.bytesize).to eq(3 * 3 * 1)
    end

    it "extracts strip data from header" do
      data = build_uncompressed_tiff(width: 2, height: 2, spp: 3)
      info = described_class.parse_header(data)
      expect(info[:compression]).to eq(1)
      expect(info[:strip_offsets]).to be_a(Integer)
      expect(info[:strip_byte_counts]).to eq(12) # 2*2*3
    end
  end

  describe Pdfrb::ImageLoader::GIF, "decode" do
    def build_minimal_gif(width:, height:, palette:)
      # Minimal GIF87a with one image descriptor + LZW data.
      # palette must have 2^N entries; the GCT size field encodes N-1.
      gif = +"GIF87a"
      gif << [width, height].pack("v v")
      n_colors = palette.length / 3
      gct_size_field = Math.log2(n_colors).to_i - 1
      packed = 0x80 | 0x70 | gct_size_field
      gif << [packed, 0, 0].pack("C C C")
      # Global Color Table
      gif << palette.pack("C*")
      # Image descriptor
      gif << ",".b
      gif << [0, 0, width, height].pack("v v v v")
      gif << "\x00".b # packed (no local CT)
      # LZW minimum code size
      gif << "\x02".b # min code size = 2
      # Encode a tiny LZW stream that produces width*height zeros.
      codes = [4] + ([0] * (width * height)) + [5]
      bits = +""
      bitbuf = 0
      bitcount = 0
      width_bits = 3
      codes.each do |code|
        bitbuf |= (code << bitcount)
        bitcount += width_bits
        while bitcount >= 8
          bits << [bitbuf & 0xFF].pack("C")
          bitbuf >>= 8
          bitcount -= 8
        end
      end
      bits << [bitbuf & 0xFF].pack("C") if bitcount.positive?
      gif << [bits.bytesize].pack("C")
      gif << bits
      gif << "\x00".b # sub-block terminator
      gif << ";".b    # trailer
      gif
    end

    it "parses the header" do
      data = build_minimal_gif(width: 2, height: 2, palette: [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255])
      info = described_class.parse_header(data)
      expect(info[:width]).to eq(2)
      expect(info[:height]).to eq(2)
      expect(info[:global_ct_flag]).to be true
      expect(info[:global_ct_size]).to eq(4)
    end

    it "reads the global color table" do
      palette = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255]
      data = build_minimal_gif(width: 2, height: 2, palette: palette)
      info = described_class.parse_header(data)
      read = described_class.read_global_color_table(data, info)
      expect(read).to eq(palette)
    end

    it "decodes pixels via LZW" do
      palette = [0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255]
      data = build_minimal_gif(width: 2, height: 2, palette: palette)
      doc = Pdfrb::Document.new
      image = described_class.call(doc, data)
      expect(image).not_to be_nil
      expect(image.value[:Width]).to eq(2)
      expect(image.value[:Height]).to eq(2)
      # Color space is [/Indexed, /DeviceRGB, 3, <palette>]
      cs = image.value[:ColorSpace]
      expect(cs).to be_a(Array)
      expect(cs[0]).to eq(:Indexed)
      # Decoded pixel indices are FlateDecode-compressed.
      decoded = Zlib.inflate(image.stream)
      expect(decoded.bytesize).to be >= 4
    end

    it "returns nil for non-GIF" do
      expect(described_class.parse_header("not a gif")).to eq({})
    end
  end

  describe Pdfrb::Color::DefaultProfile, "complete ICC profile" do
    it "emits a profile large enough to include the tag table + tags" do
      bytes = described_class.srgb_bytes
      expect(bytes.bytesize).to be > 300
      expect(bytes.byteslice(36, 4)).to eq("acsp")
    end

    it "tag count is non-zero" do
      bytes = described_class.srgb_bytes
      tag_count = bytes.unpack1("N", offset: 128)
      expect(tag_count).to eq(8) # desc + wtpt + rXYZ + gXYZ + bXYZ + rTRC + gTRC + bTRC
    end

    it "patches the Profile ID with an MD5 of the body" do
      bytes = described_class.srgb_bytes
      id = bytes.byteslice(84, 16)
      expect(id).not_to eq("\x00" * 16)
    end

    it "passes structural validation" do
      bytes = described_class.srgb_bytes
      expect(Pdfrb::Color::ICCValidator.valid?(bytes)).to be true
    end

    it "srgb_color_space returns an ICCBased color-space array" do
      doc = Pdfrb::Document.new
      cs = described_class.srgb_color_space(doc)
      expect(cs).to be_a(Array)
      expect(cs.first).to eq(:ICCBased)
    end
  end

  describe Pdfrb::Layout::PolygonFrame, "inscribed rectangle" do
    it "finds a slot in a rectangular polygon" do
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 100,
                                  polygon: [[0, 0], [100, 0], [100, 100], [0, 100]],
                                  step: 1)
      result = frame.find_available_area(30, 30)
      expect(result).not_to be_nil
      _x, y, w, h = result
      expect(w).to eq(30)
      expect(h).to eq(30)
      expect(y).to be <= 100
    end

    it "returns nil when nothing fits" do
      # Tight polygon (10x10) — a 50x50 box can't fit.
      frame = described_class.new(left: 0, bottom: 0, width: 10, height: 10,
                                  polygon: [[0, 0], [10, 0], [10, 10], [0, 10]],
                                  step: 1)
      expect(frame.find_available_area(50, 50)).to be_nil
    end

    it "bounding_box accessors return polygon extents" do
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 100,
                                  polygon: [[10, 20], [80, 20], [80, 90], [10, 90]],
                                  step: 1)
      expect(frame.bounding_box_left).to eq(10)
      expect(frame.bounding_box_right).to eq(80)
      expect(frame.bounding_box_bottom).to eq(20)
      expect(frame.bounding_box_top).to eq(90)
    end

    it "finds a slot in an L-shaped polygon" do
      # L-shape: bottom-left rectangle 0..100 x 0..50, top-right
      # rectangle 50..100 x 50..100.
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 100,
                                  polygon: [
                                    [0, 0], [100, 0], [100, 50], [50, 50],
                                    [50, 100], [0, 100]
                                  ],
                                  step: 1)
      # A 30x30 box should fit somewhere.
      result = frame.find_available_area(30, 30)
      expect(result).not_to be_nil
    end
  end
end
