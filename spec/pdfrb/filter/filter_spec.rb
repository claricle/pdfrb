# frozen_string_literal: true

require "spec_helper"
require "zlib"

RSpec.describe Pdfrb::Filter do
  describe "registry" do
    it "looks up FlateDecode" do
      expect(described_class["FlateDecode"]).to eq(Pdfrb::Filter::FlateDecode)
    end

    it "looks up ASCIIHexDecode" do
      expect(described_class["ASCIIHexDecode"]).to eq(Pdfrb::Filter::ASCIIHexDecode)
    end
  end

  describe ".apply" do
    it "returns bytes unchanged for an empty filter list" do
      expect(described_class.apply("x".b, filters: [], parms: [], direction: :decode)).to eq("x".b)
    end

    it "decodes FlateDecode" do
      raw = "hello world".b
      encoded = Zlib::Deflate.deflate(raw)
      result = described_class.apply(encoded, filters: [:FlateDecode], parms: [nil],
                                                direction: :decode)
      expect(result).to eq(raw)
    end

    it "encodes via FlateDecode (and round-trips)" do
      raw = "compress me".b
      encoded = described_class.apply(raw, filters: [:FlateDecode], parms: [nil],
                                               direction: :encode)
      decoded = described_class.apply(encoded, filters: [:FlateDecode], parms: [nil],
                                                direction: :decode)
      expect(decoded).to eq(raw)
    end

    it "raises FilterError for unknown filter" do
      expect {
        described_class.apply("x".b, filters: ["Bogus"], parms: [], direction: :decode)
      }.to raise_error(Pdfrb::FilterError)
    end

    it "applies ASCIIHexDecode" do
      bytes = "48656c6c6f>".b
      expect(described_class.apply(bytes, filters: [:ASCIIHexDecode], parms: [nil],
                                              direction: :decode)).to eq("Hello".b)
    end
  end
end

RSpec.describe Pdfrb::Filter::FlateDecode do
  it "decodes + encodes" do
    raw = "the quick brown fox".b
    encoded = described_class.encoder(raw, nil, nil)
    expect(described_class.decoder(encoded, nil, nil)).to eq(raw)
  end
end

RSpec.describe Pdfrb::Filter::ASCIIHexDecode do
  it "decodes hex" do
    expect(described_class.decoder("48656c6c6f>".b, nil, nil)).to eq("Hello".b)
  end

  it "encodes hex with EOD marker" do
    expect(described_class.encoder("Hello".b, nil, nil)).to eq("48656c6c6f>".b)
  end

  it "tolerates whitespace" do
    expect(described_class.decoder("48 65 6c 6c 6f >".b, nil, nil)).to eq("Hello".b)
  end

  it "pads odd nibble with 0" do
    expect(described_class.decoder("4>".b, nil, nil)).to eq("\x40".b)
  end
end
