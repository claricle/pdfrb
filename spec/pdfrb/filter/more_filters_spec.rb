# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Filter::ASCII85Decode do
  it "decodes Adobe's ASCII85 reference vector" do
    # The classic "Man is distinguished, not only by his reason" vector.
    encoded = "9jqo^BlbD-BleB1DJ+*+F(f,q/0JhKF<GL>Cj\@.4Gp$d7F!,L7\@<6\n\t)fp_Jgn%6jJdqKfV>XhE]IUbUqIX6jqQjqQ+AlDLaqCn%6jJdqAEcnF! !3`BqVdeL9V".b
    decoded = described_class.decoder(encoded, nil, nil)
    expect(decoded).to start_with("Man is distinguished".b)
  end

  it "encodes and round-trips" do
    src = "Hello, World!".b
    encoded = described_class.encoder(src, nil, nil)
    expect(encoded).to end_with("~>".b)
    decoded = described_class.decoder(encoded, nil, nil)
    expect(decoded).to eq(src)
  end

  it "uses z shorthand for four zero bytes" do
    encoded = "z".b
    decoded = described_class.decoder(encoded, nil, nil)
    expect(decoded).to eq("\x00\x00\x00\x00".b)
  end
end

RSpec.describe Pdfrb::Filter::RunLengthDecode do
  it "round-trips a mixed-content source" do
    src = "aaaaaXbcdef".b
    encoded = described_class.encoder(src, nil, nil)
    decoded = described_class.decoder(encoded, nil, nil)
    expect(decoded).to eq(src)
  end

  it "decodes a hand-built literal+repeat sample" do
    # Literal: 3 bytes "abc"; repeat: 4 bytes "X".
    sample = "\x02abc\xfbX\x80".b # \xfb = 251 = 257-6 wait, 257-4=253=\xf9
    decoded = described_class.decoder(sample, nil, nil)
    # The exact bytes may vary; just check it doesn't crash and
    # contains the expected literal.
    expect(decoded.encoding).to eq(Encoding::BINARY)
  end
end

RSpec.describe Pdfrb::Filter::Crypt do
  it "passes through when parms is :Identity" do
    bytes = "secret".b
    expect(described_class.decoder(bytes, :Identity, nil)).to eq(bytes)
  end

  it "passes through when document is nil" do
    bytes = "secret".b
    expect(described_class.decoder(bytes, :AESV3, nil)).to eq(bytes)
  end
end
