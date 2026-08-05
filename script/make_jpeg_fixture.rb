# frozen_string_literal: true

# Build a minimal 2x1 RGB JPEG fixture for image_loader specs.
# Uses the JPEG spec directly (no ImageMagick). The output is intentionally
# minimal — just enough to be recognized by JPEG parsers and contain valid
# SOF/SOS segments describing a 2x1 RGB image.
bytes = +""
# SOI
bytes << "\xFF\xD8".b
# DQT (Define Quantization Table) — minimal valid 1-byte table
bytes << "\xFF\xDB".b           # marker
bytes << "\x00\x43".b           # length = 67
bytes << "\x00".b               # table id 0, precision 0 (8-bit)
# 64 quantization values, all 1
64.times { bytes << "\x01".b }
# SOF0 (Start Of Frame, baseline) — 2x1 RGB
bytes << "\xFF\xC0".b          # marker
bytes << "\x00\x0B".b          # length = 11
bytes << "\x08".b               # precision 8-bit
bytes << "\x00\x01".b          # height = 1
bytes << "\x00\x02".b          # width = 2
bytes << "\x03".b               # num components = 3 (YCbCr)
bytes << "\x01\x11\x00".b      # Y component (id=1, sampling 1x1, quant table 0)
bytes << "\x02\x11\x00".b      # Cb component (id=2, sampling 1x1, quant table 0)
bytes << "\x03\x11\x00".b      # Cr component (id=3, sampling 1x1, quant table 0)
# DHT (Define Huffman Table) — minimal DC table for each component
def huffman_table(bytes, table_class, table_id)
  bytes << "\xFF\xC4".b
  # 16 bytes of bit-length counts (all zero for simplicity except code 0)
  lengths = [0] * 16
  lengths[0] = 1  # one code of length 1
  payload = [table_class << 4 | table_id].pack("C") + lengths.pack("C16")
  body = payload
  body << "\x00".b  # one symbol value = 0
  bytes << [body.bytesize + 2].pack("n") + body.b
end
huffman_table(bytes, 0, 0)  # DC table 0
huffman_table(bytes, 1, 0)  # AC table 0
# SOS (Start Of Scan)
bytes << "\xFF\xDA".b
bytes << "\x00\x08".b           # length
bytes << "\x03".b               # 3 components
bytes << "\x01\x00".b          # Y id=1, DC table 0, AC table 0
bytes << "\x02\x00".b          # Cb id=2, DC table 0, AC table 0
bytes << "\x03\x00".b          # Cr id=3, DC table 0, AC table 0
bytes << "\x00\x3F\x00".b      # spectral selection 0..63, successive approx 0
# Entropy-coded data — minimal placeholder bytes; not a valid scan but accepted
bytes << "\x00".b
# EOI
bytes << "\xFF\xD9".b
bytes.force_encoding(Encoding::BINARY)
File.binwrite("spec/fixtures/images/test.jpg", bytes)
puts "JPEG written: #{bytes.bytesize} bytes"