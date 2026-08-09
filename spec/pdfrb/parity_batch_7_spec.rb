# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Parity batch 7 — bulk TODO completion" do
  describe Pdfrb::Conformance::Pades do
    let(:doc) { Pdfrb::Document.new }

    it "validates B-B baseline" do
      result = described_class.validate(doc, level: :"B-B")
      expect(result.profile).to eq("PAdES-B-B")
    end

    it "validates B-T" do
      result = described_class.validate(doc, level: :"B-T")
      expect(result.profile).to eq("PAdES-B-T")
    end

    it "validates B-LT" do
      result = described_class.validate(doc, level: :"B-LT")
      expect(result.profile).to eq("PAdES-B-LT")
    end

    it "validates B-LTA" do
      result = described_class.validate(doc, level: :"B-LTA")
      expect(result.profile).to eq("PAdES-B-LTA")
    end

    it "flags missing DSS for B-LT" do
      result = described_class.validate(doc, level: :"B-LT")
      expect(result.violations.map(&:rule_id)).to include("blt-1")
    end
  end

  describe Pdfrb::Conformance::Ltv do
    it "requires /DSS" do
      doc = Pdfrb::Document.new
      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).to include("ltv-1")
    end

    it "passes when /DSS is present" do
      doc = Pdfrb::Document.new
      doc.catalog.value[:DSS] = { Certs: [Pdfrb::Model::Reference.new(999, 0)] }
      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).not_to include("ltv-1")
    end
  end

  describe Pdfrb::Conformance::PdfA4Deep do
    it "requires XMP /Metadata" do
      doc = Pdfrb::Document.new
      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).to include("a4deep-1")
    end

    it "forbids EmbeddedFile" do
      doc = Pdfrb::Document.new
      doc.add({ Type: :EmbeddedFile }, type: Pdfrb::Model::Cos::Stream)
      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).to include("a4deep-3")
    end
  end

  describe Pdfrb::Conformance::PdfUA2Deep do
    it "requires PDF 2.0" do
      doc = Pdfrb::Document.new
      doc.version = "1.7"
      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).to include("ua2-1")
    end
  end

  describe Pdfrb::Conformance::PdfUATaggingDeep do
    it "warns about /L without /LI" do
      doc = Pdfrb::Document.new
      tree = doc.add({ Type: :StructTreeRoot }, type: Pdfrb::Model::Cos::Dictionary)
      l = doc.add({ Type: :StructElem, S: :L }, type: Pdfrb::Model::Cos::Dictionary)
      tree.value[:K] = [Pdfrb::Model::Reference.new(l.oid, l.gen)]
      doc.catalog.value[:StructTreeRoot] = Pdfrb::Model::Reference.new(tree.oid, tree.gen)
      doc.catalog.value[:MarkInfo] = { Marked: true }

      result = described_class.validate(doc)
      expect(result.violations.map(&:rule_id)).to include("tag-deep-1")
    end
  end

  describe Pdfrb::Layout::TextShaper do
    it "returns shaped runs with default implementation" do
      run = described_class.shape("Hi")
      expect(run.codepoints).to eq("Hi".codepoints.to_a)
      expect(run.advances.length).to eq(2)
    end

    it "uses a registered implementation when set" do
      shim = Module.new do
        def self.shape(text, **)
          Pdfrb::Layout::TextShaper::ShapedRun.new(
            codepoints: text.to_s.codepoints.to_a.reverse,
            clusters: [], advances: []
          )
        end
      end
      original = described_class.implementation
      described_class.implementation = shim
      run = described_class.shape("Hi")
      expect(run.codepoints).to eq("iH".codepoints.to_a)
    ensure
      described_class.implementation = original
    end
  end

  describe Pdfrb::Layout::PolygonFrame do
    it "creates a frame with a polygon shape" do
      frame = described_class.new(left: 0, bottom: 0, width: 100, height: 100,
                                  polygon: [[0, 0], [100, 0], [100, 100], [0, 100]])
      expect(frame.contains_point?(50, 50)).to be true
      expect(frame.contains_point?(150, 150)).to be false
    end
  end

  describe Pdfrb::Layout::FontFallback do
    it "picks primary when it covers the codepoint" do
      fb = described_class.new
      expect(fb.pick("A".ord, primary: "Helvetica")).to eq("Helvetica")
    end

    it "falls back through the chain when primary doesn't cover" do
      fb = described_class.new(chain: ["Helvetica", "Symbol"])
      expect(fb.pick(0x2603, primary: nil)).to be_nil.or(eq("Helvetica"))
    end

    it "segments text by font coverage" do
      fb = described_class.new
      segs = fb.segment("Hello")
      expect(segs).to be_an(Array)
      expect(segs.length).to be_positive
    end
  end

  describe Pdfrb::Layout::JustificationKashidas do
    it "returns text unchanged when target met" do
      result = described_class.justify("hi", target_width: 10,
                                             measure: ->(_s) { 50 })
      expect(result).to eq("hi")
    end

    it "insertion points detect right-joining Arabic pairs" do
      points = described_class.kashida_insertion_points("بب")
      expect(points).to include(1)
    end
  end

  describe Pdfrb::Layout::MultiCellTextLayout do
    it "lays out text across multiple bands" do
      bands = [[0, 700, 200, 100], [0, 500, 200, 100]]
      layout = described_class.new(bands: bands, style: Pdfrb::Layout::Style.new(:base))
      result = layout.layout("Hello world from pdfrb")
      expect(result).to be_an(Array)
    end
  end

  describe Pdfrb::FontLoader::Type3 do
    it "builds a Type3 font dict from glyph specs" do
      doc = Pdfrb::Document.new
      glyphs = [
        Pdfrb::FontLoader::Type3::GlyphSpec.new(name: :A, width: 500,
                                                procedure: "500 0 d1\n0 0 500 700 re f\n"),
        Pdfrb::FontLoader::Type3::GlyphSpec.new(name: :B, width: 500,
                                                procedure: "500 0 d1\n0 0 250 700 re f\n"),
      ]
      loader = described_class.new(document: doc, glyphs: glyphs,
                                   bounding_box: [0, 0, 1000, 1000])
      font = loader.build
      expect(font.value[:Subtype]).to eq(:Type3)
      expect(font.value[:CharProcs]).to be_a(Hash)
    end
  end

  describe Pdfrb::Encryption::PublicKeySecurityHandler do
    it "instantiates with encrypt_dict and recipients" do
      handler = described_class.new(encrypt_dict: { V: 5 },
                                    recipients: [],
                                    private_key: nil)
      expect(handler.can_decrypt?).to be false
    end
  end

  describe Pdfrb::Encryption::V5Writer do
    it "builds a 48-byte U entry" do
      u = described_class.build_u_entry(
        password: "pw",
        validation_salt: "v" * 8,
        key_salt: "k" * 8
      )
      expect(u.bytesize).to eq(48)
    end

    it "extracts salts from a U entry" do
      u = described_class.build_u_entry(
        password: "pw",
        validation_salt: "\x01" * 8,
        key_salt: "\x02" * 8
      )
      _hash, vsalt, ksalt = described_class.extract_v5_salts(u)
      expect(vsalt).to eq("\x01" * 8)
      expect(ksalt).to eq("\x02" * 8)
    end
  end

  describe Pdfrb::DigitalSignature::TimestampClient do
    it "builds a TimeStampReq DER" do
      der = described_class.build_tsq_request("data" * 8, "sha256")
      expect(der).to be_a(String)
      expect(der.bytesize).to be_positive
    end
  end

  describe Pdfrb::Source::Recovery, "extended" do
    let(:pdf_with_root) do
      src = Pdfrb::Document.new
      src.pages.add
      out = StringIO.new
      src.write(io: out)
      out.string
    end

    it "recovers trailer references from a binary scan" do
      refs = described_class.recover_trailer_references(StringIO.new(pdf_with_root))
      expect(refs[:Root]).to be_a(Pdfrb::Model::Reference)
    end

    it "detects hybrid xref by scanning both markers" do
      hybrid = +"%PDF-1.7\nxref\n0 1\n0000000000 65535 f \n/Type /XRef\n"
      expect(described_class.hybrid_xref?(StringIO.new(hybrid))).to be true
    end

    it "returns false for non-hybrid PDFs" do
      expect(described_class.hybrid_xref?(StringIO.new(pdf_with_root))).to be false
    end
  end

  describe Pdfrb::ImageLoader::TIFF do
    it "detects little-endian TIFF" do
      data = +"II" # little-endian
      data << [42].pack("S<") # magic
      data << [8].pack("L<")  # IFD offset placeholder (will patch)
      # Skip to where the IFD will actually live (offset 16)
      data << ("\x00" * 4)
      # IFD at offset 16
      ifd_offset = data.bytesize
      data[4, 4] = [ifd_offset].pack("L<")
      # 1 entry: tag=256 (ImageWidth), type=3 (SHORT), count=1, value=640
      data << [1].pack("S<") # tag count
      data << [256, 3, 1].pack("S< S< L<")
      data << [640].pack("S<")
      data << "\x00\x00".b # pad value to 4 bytes
      info = described_class.parse_header(data)
      expect(info[:width]).to eq(640)
    end

    it "returns empty for non-TIFF" do
      expect(described_class.parse_header("not a tiff")).to eq({})
    end
  end

  describe Pdfrb::ImageLoader::GIF do
    it "detects GIF87a" do
      data = +"GIF87a"
      data << [640, 480].pack("v v") # logical screen
      data << "\x00\x00\x00" # packed, bg, aspect
      info = described_class.parse_header(data)
      expect(info[:width]).to eq(640)
      expect(info[:height]).to eq(480)
    end

    it "returns empty for non-GIF" do
      expect(described_class.parse_header("not a gif")).to eq({})
    end
  end

  describe Pdfrb::Color::DefaultProfile do
    it "produces minimal sRGB ICC bytes with valid header" do
      bytes = described_class.srgb_bytes
      expect(bytes.bytesize).to be >= 128
      expect(bytes.byteslice(36, 4)).to eq("acsp")
    end

    it "builds an ICCBased color space array" do
      doc = Pdfrb::Document.new
      cs = described_class.srgb_color_space(doc)
      expect(cs).to be_an(Array)
      expect(cs.first).to eq(:ICCBased)
    end
  end

  describe Pdfrb::Color::ICCValidator do
    it "validates the default sRGB profile bytes" do
      bytes = Pdfrb::Color::DefaultProfile.srgb_bytes
      violations = described_class.validate(bytes)
      expect(violations).to eq([])
    end

    it "rejects tiny byte strings" do
      violations = described_class.validate("x")
      expect(violations.first).to include("too small")
    end

    it "rejects bad acsp signature" do
      bytes = "\x00" * 132
      violations = described_class.validate(bytes)
      expect(violations).to include("ICC profile signature at offset 36 is not 'acsp'")
    end
  end
end
