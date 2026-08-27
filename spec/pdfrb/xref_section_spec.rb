# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::XrefSection do
  it "records in-use entries and grows the size" do
    section = described_class.new
    section.add_in_use(4, 0, 0x0AB)
    expect(section.size).to eq(5)

    entry = section[4]
    expect(entry).to be_in_use
    expect(entry.offset).to eq(0x0AB)
    expect(entry.gen).to eq(0)
  end

  it "records free entries with the next-free oid" do
    section = described_class.new(size: 10)
    section.add_free(6, 0, 7)
    expect(section[6]).to be_free
    expect(section[6].offset).to eq(7)
    expect(section.size).to eq(10)
  end

  it "records compressed entries with their ObjStm home" do
    section = described_class.new
    section.add_compressed(12, 5, 3)
    entry = section[12]
    expect(entry).to be_compressed
    expect(entry.obj_stm_oid).to eq(5)
    expect(entry.index).to eq(3)
    expect(section.size).to eq(13)
  end

  it "iterates entries in insertion order" do
    section = described_class.new
    section.add_in_use(2, 0, 10)
    section.add_in_use(1, 0, 5)
    expect(section.each_entry.map(&:first)).to eq([2, 1])
  end

  it "merges without overwriting existing entries" do
    a = described_class.new
    a.add_in_use(3, 0, 111)
    a.add_free(0, 65535, 3)

    b = described_class.new
    b.add_in_use(3, 0, 999)
    b.add_in_use(4, 0, 222)

    a.merge!(b)
    expect(a[3].offset).to eq(111)
    expect(a[4].offset).to eq(222)
    expect(a.size).to eq(5)
  end
end

RSpec.describe Pdfrb::DataDir do
  it "resolves existing data files under the gem root" do
    path = described_class.resolve("arlington", "latest", "Catalog.tsv")
    expect(path).to start_with(described_class.root)
    expect(File).to exist(path)
  end

  it "raises a typed error for missing data files" do
    expect { described_class.resolve("nope", "missing.tsv") }
      .to raise_error(Pdfrb::Error, /missing data file/)
  end

  it "exposes the Arlington directory for a version" do
    latest = described_class.arlington
    expect(latest).to end_with("arlington/latest")
    expect(File.directory?(latest)).to be true
  end
end
