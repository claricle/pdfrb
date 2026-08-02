# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Date do
  it "parses a minimal D:YYYY date" do
    expect(described_class.parse("D:2026").year).to eq(2026)
  end

  it "parses a full date with UTC offset" do
    t = described_class.parse("D:20260730120000Z")
    expect(t.year).to eq(2026)
    expect(t.month).to eq(7)
    expect(t.day).to eq(30)
    expect(t.utc_offset).to eq(0)
  end

  it "parses a date with a + offset" do
    t = described_class.parse("D:20260730120000+02'00'")
    expect(t.utc_offset).to eq(7200)
  end

  it "tolerates a missing D: prefix" do
    expect(described_class.parse("20260730").year).to eq(2026)
  end

  it "returns nil for nil/empty input" do
    expect(described_class.parse(nil)).to be_nil
    expect(described_class.parse("")).to be_nil
  end

  it "raises ParseError on garbage" do
    expect { described_class.parse("not a date") }.to raise_error(Pdfrb::ParseError)
  end

  it "round-trips through format/parse" do
    t = Time.new(2026, 7, 30, 12, 0, 0, "+02:00")
    s = described_class.format(t)
    re = described_class.parse(s)
    expect(re.utc_offset).to eq(7200)
    expect(re.year).to eq(2026)
  end
end
