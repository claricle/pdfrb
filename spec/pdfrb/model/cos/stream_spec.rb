# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Cos::Stream do
  let(:doc) { Pdfrb::Document.new }

  it "is a Dictionary with bytes" do
    s = described_class.new({ Type: :XRef }, stream: "hello".b)
    expect(s).to be_a(Pdfrb::Model::Cos::Dictionary)
    expect(s.stream).to eq("hello".b)
    expect(s.stream.encoding).to eq(Encoding::BINARY)
  end

  it "force-encodes the stream to BINARY" do
    s = described_class.new({}, stream: "abc")
    expect(s.stream.encoding).to eq(Encoding::BINARY)
  end

  it "returns raw bytes when no filter" do
    s = described_class.new({}, stream: "abc")
    expect(s.decoded_stream).to eq("abc".b)
  end

  it "applies FlateDecode when /Filter is set" do
    require "zlib"
    raw = "hello world".b
    encoded = Zlib::Deflate.deflate(raw)
    s = described_class.new({ Filter: :FlateDecode, Length: encoded.bytesize },
                            stream: encoded, document: doc)
    expect(s.decoded_stream).to eq(raw)
  end

  it "raises FilterError on a corrupt Flate stream" do
    s = described_class.new({ Filter: :FlateDecode },
                            stream: "garbage".b, document: doc)
    expect { s.decoded_stream }.to raise_error(Pdfrb::FilterError)
  end
end
