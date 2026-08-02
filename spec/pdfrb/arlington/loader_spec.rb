# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Arlington::Loader do
  after { described_class.clear_cache! }

  describe ".object_definition" do
    it "loads the Catalog TSV" do
      defn = described_class.object_definition("Catalog")
      expect(defn).to be_a(Pdfrb::Arlington::ObjectDefinition)
      expect(defn.name).to eq("Catalog")
    end

    it "caches parsed definitions" do
      first = described_class.object_definition("Catalog")
      second = described_class.object_definition("Catalog")
      expect(first).to be(second)
    end

    it "raises when the TSV is missing" do
      expect {
        described_class.object_definition("NoSuchObject")
      }.to raise_error(Pdfrb::Error)
    end

    it "parses the FileTrailer TSV with all expected keys" do
      defn = described_class.object_definition("FileTrailer")
      keys = defn.keys
      %w[Size Prev Root Encrypt Info ID XRefStm].each do |k|
        expect(keys).to include(k)
      end
    end
  end

  describe ".list_object_names" do
    it "lists hundreds of object definitions" do
      names = described_class.list_object_names
      expect(names.length).to be > 500
      expect(names).to include("Catalog", "FileTrailer", "PageObject")
    end
  end
end

RSpec.describe Pdfrb::Arlington::ObjectDefinition do
  subject(:defn) { Pdfrb::Arlington::Loader.object_definition("Catalog") }

  it "exposes its name and fields" do
    expect(defn.name).to eq("Catalog")
    expect(defn.fields.length).to be > 20
  end

  it "looks up a field by key" do
    field = defn.field_for("Pages")
    expect(field).not_to be_nil
    expect(field.types).to include(:dictionary)
  end

  it "iterates via each_field" do
    keys = []
    defn.each_field { |f| keys << f.key }
    expect(keys).to include("Type", "Pages", "PageLayout")
  end
end

RSpec.describe Pdfrb::Arlington::FieldDefinition, "#types" do
  it "splits the Type column on ;" do
    defn = Pdfrb::Arlington::Loader.object_definition("PageObject")
    contents = defn.field_for("Contents")
    expect(contents.types).to include(:array, :stream)
  end

  it "exposes required? for TRUE rows" do
    defn = Pdfrb::Arlington::Loader.object_definition("FileTrailer")
    size = defn.field_for("Size")
    expect(size).to be_required
    expect(size.required_literal).to eq(true)
  end

  it "exposes a predicate string when Required is fn:IsRequired(...)" do
    defn = Pdfrb::Arlington::Loader.object_definition("FileTrailer")
    info = defn.field_for("Info")
    # Info's Required is fn:IsRequired(...) per the TSV
    expect(info.required_predicate?).to be(true)
  end

  it "extracts links" do
    defn = Pdfrb::Arlington::Loader.object_definition("Catalog")
    pages = defn.field_for("Pages")
    expect(pages.links).to include("PageTreeNodeRoot")
  end

  it "extracts possible_values" do
    defn = Pdfrb::Arlington::Loader.object_definition("Catalog")
    page_layout = defn.field_for("PageLayout")
    expect(page_layout.possible_value_list).to include("SinglePage", "OneColumn")
  end
end
