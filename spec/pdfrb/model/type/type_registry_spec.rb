# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Model::Type::* registry completeness" do
  it "registers Catalog" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map[:Catalog]).to eq(Pdfrb::Model::Type::Catalog)
  end

  it "registers Page" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map[:Page]).to eq(Pdfrb::Model::Type::Page)
  end

  it "registers Annotation" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map[:Page]).to eq(Pdfrb::Model::Type::Page)
  end

  it "registers Font" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map[:Metadata]).to eq(Pdfrb::Model::Type::Metadata)
  end

  it "registers PageTreeNode" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map[:Pages]).to eq(Pdfrb::Model::Type::PageTreeNode)
  end

  it "registers at least 30 type mappings" do
    expect(Pdfrb::Model::Cos::Dictionary.type_map.size).to be >= 30
  end
end

RSpec.describe "Action types" do
  it "registers GoTo action" do
    doc = Pdfrb::Document.new
    action = doc.add({ Type: :Action, S: :GoTo, D: [0, :Fit] },
                     type: Pdfrb::Model::Cos::Dictionary)
    expect(action).to be_a(Pdfrb::Model::Cos::Dictionary)
  end

  it "registers URI action" do
    doc = Pdfrb::Document.new
    action = doc.add({ Type: :Action, S: :URI, URI: "https://example.com" },
                     type: Pdfrb::Model::Cos::Dictionary)
    expect(action[:URI]).to eq("https://example.com")
  end

  it "registers JavaScript action" do
    doc = Pdfrb::Document.new
    action = doc.add({ Type: :Action, S: :JavaScript, JS: "app.alert('test')" },
                     type: Pdfrb::Model::Cos::Dictionary)
    expect(action[:JS]).to include("alert")
  end
end

RSpec.describe "Annotation subtypes" do
  it "creates annotation dicts with subtypes" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    %i[Text Link Stamp Circle Square Ink Line Polygon PolyLine Widget].each do |subtype|
      annot = doc.annotations.add(page, subtype: subtype, rect: [0, 0, 10, 10])
      expect(annot[:Subtype]).to eq(subtype)
    end
  end
end

RSpec.describe "Form field types" do
  it "creates text field" do
    doc = Pdfrb::Document.new
    field = doc.add({ Type: :Annot, FT: :Tx, T: "name", V: "test" },
                    type: Pdfrb::Model::Cos::Dictionary)
    expect(field[:FT]).to eq(:Tx)
    expect(field[:T]).to eq("name")
  end

  it "creates button field" do
    doc = Pdfrb::Document.new
    field = doc.add({ Type: :Annot, FT: :Btn, T: "check", V: :Yes },
                    type: Pdfrb::Model::Cos::Dictionary)
    expect(field[:V]).to eq(:Yes)
  end
end

RSpec.describe "ViewerPreferences" do
  it "reads hide toolbar flag" do
    doc = Pdfrb::Document.new
    vp = doc.add({ Type: :ViewerPreferences, HideToolbar: true },
                 type: Pdfrb::Model::Type::ViewerPreferences)
    expect(vp.hide_toolbar?).to be true
  end

  it "reads direction" do
    doc = Pdfrb::Document.new
    vp = doc.add({ Type: :ViewerPreferences, Direction: :R2L },
                 type: Pdfrb::Model::Type::ViewerPreferences)
    expect(vp.direction).to eq(:R2L)
  end
end

RSpec.describe "MarkInformation" do
  it "reads marked flag" do
    doc = Pdfrb::Document.new
    mi = doc.add({ Type: :MarkInfo, Marked: true },
                 type: Pdfrb::Model::Type::MarkInformation)
    expect(mi.marked?).to be true
  end
end

RSpec.describe "PageLabel" do
  it "reads style and prefix" do
    doc = Pdfrb::Document.new
    pl = doc.add({ Type: :PageLabel, S: :D, P: "Page ", St: 5 },
                 type: Pdfrb::Model::Type::PageLabel)
    expect(pl.style).to eq(:D)
    expect(pl.prefix).to eq("Page ")
    expect(pl.start).to eq(5)
  end
end
