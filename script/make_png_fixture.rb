# frozen_string_literal: true

require "zlib"

width = 2
height = 2
raw = +""
raw << "\x00".b << "\xff\x00\x00".b << "\x00\xff\x00".b
raw << "\x00".b << "\x00\x00\xff".b << "\xff\xff\x00".b
raw.force_encoding(Encoding::BINARY)
compressed = Zlib::Deflate.deflate(raw)

def chunk(name, data)
  name_b = name.dup.force_encoding(Encoding::BINARY)
  len = [data.bytesize].pack("N")
  crc = [Zlib::crc32(name_b + data, 0)].pack("N")
  (len + name_b + data + crc).force_encoding(Encoding::BINARY)
end

png = "\x89PNG\r\n\x1a\n".b
png << chunk("IHDR", [width, height, 8, 2, 0, 0, 0].pack("NNCCCCC"))
png << chunk("IDAT", compressed)
png << chunk("IEND", "")
File.binwrite("spec/fixtures/images/test.png", png)
puts "PNG written: #{png.bytesize} bytes"
