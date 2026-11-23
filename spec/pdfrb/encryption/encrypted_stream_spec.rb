# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "encrypted stream /Length and EOL handling" do
  # Regression coverage for a data-dependent round-trip failure in
  # V4/AESV2 (bits: 128) encrypted documents:
  #
  # 1. Writer: the serializer baked /Length from the plaintext payload
  #    and only then encrypted it — AESV2 grows the payload (16-byte IV
  #    plus padding), so every encrypted stream carried a stale /Length
  #    (RC4 for 40-bit preserved length, which masked the bug).
  # 2. Reader: scan_to_endstream stripped /\r?\n/ from the recovered
  #    span, so when the last ciphertext byte happened to be 0x0D the
  #    tail looked like "\r\n" and TWO bytes were dropped, breaking AES
  #    block alignment.
  # 3. Reader: decrypt_aes_cbc rescued CipherError and silently handed
  #    back the raw ciphertext — the exact behaviour its own comment
  #    forbids.

  def encrypted_pdf(bits: 128)
    doc = Pdfrb::Document.new
    font = doc.fonts.add("Helvetica")
    2.times do |i|
      doc.pages.add.canvas.text("Secret page #{i + 1}", at: [72, 720], font: font, size: 12)
    end
    doc.encrypt!(user_password: "s3cret", owner_password: "s3cret", bits: bits)

    io = StringIO.new
    doc.write(io: io)
    io.string
  end

  def contents_span(pdf)
    # The page Contents stream: object numbering is not hardcoded.
    probe = Pdfrb::Document.new(io: StringIO.new(pdf),
                                config: { "encryption.password" => "s3cret" })
    contents_ref_oid = probe.pages.first.value[:Contents].oid

    pdf.match(/#{contents_ref_oid} 0 obj\s*<<.*?>>\s*stream\n(.*?)\nendstream/m)&.[](1)
  end

  it "declares /Length equal to the actual stored stream bytes" do
    pdf = encrypted_pdf
    pdf.scan(/(\d+ 0 obj\n<<.*?>>\s*stream\n)(.*?)\nendstream/m).each do |head, payload|
      declared = head[/\/Length\s+(\d+)/, 1]
      expect(payload.bytesize).to eq(declared.to_i),
                                  "stream #{head[/\d+/]} declared /Length " \
                                  "#{declared} but stored #{payload.bytesize} bytes"
    end
  end

  it "stores AESV2 stream payloads as IV + block-aligned ciphertext" do
    # AESV2 payload = 16-byte IV + PKCS#7-padded ciphertext: always a
    # multiple of 16. The stale-/Length bug produced 79-byte payloads.
    span = contents_span(encrypted_pdf)
    expect(span.bytesize % 16).to eq(0)
  end

  it "survives ciphertext whose last byte is CR (the \\r\\n ambiguity)" do
    # The reader's recovery strips a trailing EOL. When the last
    # ciphertext byte happens to be 0x0D, the tail looks like "\r\n".
    # Deterministic crafted coverage of that ambiguity lives in
    # spec/pdfrb/source/parser_spec.rb; here we pin the round trip
    # over many random IVs, any of which may produce a CR tail.
    60.times do
      pdf = encrypted_pdf
      reopened = Pdfrb::Document.new(io: StringIO.new(pdf),
                                     config: { "encryption.password" => "s3cret" })
      content = reopened.resolve(reopened.pages.first.value[:Contents])
      expect(content.stream).to include("Secret page 1")
    end
  end

  it "raises instead of returning ciphertext when a stream fails to decrypt" do
    pdf = encrypted_pdf.dup.b
    span = contents_span(pdf)
    # CBC is not authenticated: only corrupting the final block (the
    # padding bytes) is detectable, so flip the LAST ciphertext byte.
    start = pdf.index(span)
    pos = start + span.bytesize - 1
    corrupted = pdf.dup
    corrupted.setbyte(pos, corrupted.getbyte(pos) ^ 0xFF)

    expect do
      reopened = Pdfrb::Document.new(io: StringIO.new(corrupted),
                                     config: { "encryption.password" => "s3cret" })
      reopened.resolve(reopened.pages.first.value[:Contents]).stream
    end.to raise_error(Pdfrb::EncryptionError)
  end
end
