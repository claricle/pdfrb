# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::XMP::Packet do
  it "produces a valid XMP packet with begin/end markers" do
    packet = described_class.new
    xmp = packet.to_xmp
    expect(xmp).to include("<?xpacket begin")
    expect(xmp).to include("<?xpacket end")
  end

  it "includes Dublin Core title when set" do
    packet = described_class.new
    packet.title = "My Document"
    xmp = packet.to_xmp
    expect(xmp).to include("<dc:title>")
    expect(xmp).to include("My Document")
  end

  it "includes Dublin Core creator when set" do
    packet = described_class.new
    packet.creator = "Jane Doe"
    xmp = packet.to_xmp
    expect(xmp).to include("<dc:creator>")
    expect(xmp).to include("Jane Doe")
  end

  it "includes PDF Producer when set" do
    packet = described_class.new
    packet.producer = "pdfrb 0.5"
    xmp = packet.to_xmp
    expect(xmp).to include("<pdf:Producer>")
    expect(xmp).to include("pdfrb 0.5")
  end

  it "includes XMP CreatorTool when set" do
    packet = described_class.new
    packet.creator_tool = "pdfrb"
    xmp = packet.to_xmp
    expect(xmp).to include("<xmp:CreatorTool>")
    expect(xmp).to include("pdfrb")
  end

  it "escapes XML special characters" do
    packet = described_class.new
    packet.title = "A & B <test>"
    xmp = packet.to_xmp
    expect(xmp).to include("A &amp; B &lt;test&gt;")
    expect(xmp).not_to include("A & B <test>")
  end

  it "includes all required namespaces" do
    xmp = described_class.new.to_xmp
    expect(xmp).to include("xmlns:dc")
    expect(xmp).to include("xmlns:pdf")
    expect(xmp).to include("xmlns:xmp")
    expect(xmp).to include("xmlns:rdf")
  end

  it "produces empty packet when no metadata set" do
    xmp = described_class.new.to_xmp
    expect(xmp).to include("rdf:Description")
  end
end

RSpec.describe Pdfrb::XMP::Schemas do
  describe Pdfrb::XMP::Schemas::DublinCore do
    it "creates a Dublin Core schema instance" do
      dc = described_class.new
      expect(dc).to respond_to(:title)
      expect(dc).to respond_to(:creator)
    end
  end

  describe Pdfrb::XMP::Schemas::PDF do
    it "creates a PDF schema instance" do
      pdf = described_class.new
      expect(pdf).to respond_to(:keywords)
      expect(pdf).to respond_to(:producer)
    end
  end

  describe Pdfrb::XMP::Schemas::XMPBasic do
    it "creates an XMP basic schema instance" do
      xmp = described_class.new
      expect(xmp).to respond_to(:creator_tool)
      expect(xmp).to respond_to(:create_date)
    end
  end
end

RSpec.describe Pdfrb::Document do
  it "provides a #xmp accessor that returns a Packet" do
    doc = described_class.new
    expect(doc.xmp).to be_a(Pdfrb::XMP::Packet)
  end

  it "memoizes the XMP packet" do
    doc = described_class.new
    first_call = doc.xmp
    expect(doc.xmp).to be(first_call)
  end

  it "allows setting XMP metadata" do
    doc = described_class.new
    doc.xmp.title = "Test Title"
    doc.xmp.producer = "pdfrb"
    xmp = doc.xmp.to_xmp
    expect(xmp).to include("Test Title")
    expect(xmp).to include("pdfrb")
  end
end
