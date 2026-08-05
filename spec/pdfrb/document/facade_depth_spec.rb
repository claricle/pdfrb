# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Document::Destinations do
  let(:doc) { Pdfrb::Document.new }
  let(:dests) { doc.destinations }

  it "starts empty" do
    expect(dests.empty?).to be true
    expect(dests.names).to eq([])
  end

  it "adds and looks up explicit destinations" do
    page = doc.pages.add
    destination = [Pdfrb::Model::Reference.new(page.oid, page.gen), :Fit]
    dests.add("top", destination)
    expect(dests.names).to include(:top)
    expect(dests[:top]).to eq(destination)
  end

  it "iterates names via each_name" do
    page = doc.pages.add
    ref = Pdfrb::Model::Reference.new(page.oid, page.gen)
    dests.add("a", [ref, :Fit])
    dests.add("b", [ref, :FitH])
    expect(dests.each_name.to_a.sort).to eq(%i[a b])
  end
end

RSpec.describe Pdfrb::Document::Annotations do
  let(:doc) { Pdfrb::Document.new }
  let(:page) { doc.pages.add }

  it "adds and counts basic annotations" do
    doc.annotations.add_text_note(page, rect: [0, 0, 100, 100], contents: "note")
    expect(doc.annotations.count(page)).to eq(1)
  end

  it "creates URI link annotations with embedded action" do
    annot = doc.annotations.add_link(page, rect: [0, 0, 100, 100], uri: "https://example.com")
    expect(annot[:H]).to eq(:Invert)
    action = annot[:A]
    expect(action[:S]).to eq(:URI)
    expect(action[:URI]).to eq("https://example.com")
  end

  it "creates destination link annotations" do
    page_ref = Pdfrb::Model::Reference.new(page.oid, page.gen)
    annot = doc.annotations.add_link(page, rect: [0, 0, 100, 100], dest: [page_ref, :Fit])
    expect(annot[:Dest]).to eq([page_ref, :Fit])
  end

  it "creates highlight annotations with quad points" do
    annot = doc.annotations.add_highlight(page,
                                          quad_points: [10, 10, 50, 10, 10, 20, 50, 20],
                                          contents: "highlighted")
    expect(annot[:Subtype]).to eq(:Highlight)
    expect(annot[:QuadPoints].length).to eq(8)
  end

  it "creates free-text annotations with default-appearance string" do
    annot = doc.annotations.add_free_text(page, rect: [0, 0, 200, 50],
                                                contents: "Hello",
                                                font: :Helv, font_size: 12,
                                                color: [0, 0, 1])
    expect(annot[:Subtype]).to eq(:FreeText)
    expect(annot[:DA]).to include("/Helv 12 Tf")
    expect(annot[:DA]).to include("0 0 1 rg")
  end

  it "iterates annotations across the whole document" do
    page2 = doc.pages.add
    doc.annotations.add_link(page, rect: [0, 0, 10, 10], uri: "https://1.com")
    doc.annotations.add_link(page2, rect: [0, 0, 10, 10], uri: "https://2.com")
    count = doc.annotations.each_link.count
    expect(count).to eq(2)
  end
end

RSpec.describe "V5 (AES-256) salts", :password_verification do
  it "extracts validation and key salts from a /U or /O entry" do
    entry = ("\x00".b * 32) + "VALIDATE".b + "KEYSALT1".b
    salts = Pdfrb::Encryption::PasswordVerification.extract_v5_salts(entry)
    expect(salts[:validation_salt]).to eq("VALIDATE".b)
    expect(salts[:key_salt]).to eq("KEYSALT1".b)
  end
end

RSpec.describe Pdfrb::Encryption::SecurityHandler, ".registry" do
  it "registers StandardSecurityHandler for /Filter /Standard" do
    expect(described_class.lookup("Standard")).to eq(Pdfrb::Encryption::StandardSecurityHandler)
  end

  it "returns nil for unknown filters" do
    expect(described_class.lookup("AdobePubSec")).to be_nil
  end
end
