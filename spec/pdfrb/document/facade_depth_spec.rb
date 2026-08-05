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

RSpec.describe "Model::Type::* additional depth coverage" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::EncryptionPublicKey do
    it "exposes public-key parameters" do
      enc = doc.add({ Filter: :AdobePubSec, V: 4, Length: 128,
                      Recipients: [{}, {}, {}] },
                    type: described_class)
      expect(enc.public_key?).to be true
      expect(enc.aes?).to be true
      expect(enc.key_length_bytes).to eq(16)
      expect(enc.recipient_count).to eq(3)
    end
  end

  describe Pdfrb::Model::Type::DocumentSecurityStore do
    it "counts certs/ocsp/crl entries" do
      dss = doc.add({ Type: :DSS, Certs: [{}, {}, {}], OCSPs: [{}] },
                    type: described_class)
      expect(dss.cert_count).to eq(3)
      expect(dss.ocsp_count).to eq(1)
      expect(dss.crl_count).to eq(0)
      expect(dss.has_vri?).to be false
    end
  end

  describe Pdfrb::Model::Type::OptionalContentConfiguration do
    it "decodes base state and intent" do
      config = doc.add({ BaseState: :OFF, Intent: [:View, :Print] },
                       type: described_class)
      expect(config.all_off?).to be true
      expect(config.view_intent?).to be true
      expect(config.print_intent?).to be true
    end
  end

  describe Pdfrb::Model::Type::PageLabel do
    it "renders decimal page labels with prefix" do
      label = doc.add({ S: :D, P: "Page ", St: 1 },
                      type: described_class)
      expect(label.label_for(0)).to eq("Page 1")
      expect(label.label_for(4)).to eq("Page 5")
    end

    it "renders uppercase roman numerals" do
      label = doc.add({ S: :R }, type: described_class)
      expect(label.label_for(0)).to eq("I")
      expect(label.label_for(2)).to eq("III")
      expect(label.label_for(4)).to eq("V")
    end

    it "renders lowercase letters" do
      label = doc.add({ S: :a }, type: described_class)
      expect(label.label_for(0)).to eq("a")
      expect(label.label_for(25)).to eq("z")
      expect(label.label_for(26)).to eq("aa")
    end
  end

  describe Pdfrb::Model::Type::BorderStyling do
    it "decodes border style and dash" do
      bs = doc.add({ S: :D, W: 2.5, D: [[3, 2], 0] },
                   type: described_class)
      expect(bs.dashed?).to be true
      expect(bs.solid?).to be false
      expect(bs.width).to eq(2.5)
      expect(bs.dash_array).to eq([3, 2])
      expect(bs.dash_phase).to eq(0)
    end
  end

  describe Pdfrb::Model::Type::BorderEffect do
    it "detects cloudy border" do
      be = doc.add({ S: :C, I: 2 }, type: described_class)
      expect(be.cloudy?).to be true
      expect(be.inset?).to be false
      expect(be.intensity).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::ViewerPreferences do
    it "exposes direction and duplex predicates" do
      vp = doc.add({ Direction: :R2L, Duplex: :DuplexFlipLongEdge },
                   type: described_class)
      expect(vp.right_to_left?).to be true
      expect(vp.duplex_flip_long_edge?).to be true
      expect(vp.simplex?).to be false
    end
  end

  describe Pdfrb::Model::Type::ActionGoTo do
    it "decodes page-index destinations" do
      action = doc.add({ Type: :Action, S: :GoTo, D: [3, :Fit] },
                       type: described_class)
      expect(action.page_index_destination?).to be true
      expect(action.target_page_number).to eq(3)
      expect(action.display_option).to eq([:Fit])
    end
  end

  describe Pdfrb::Model::Type::ActionURI do
    it "extracts URL scheme" do
      action = doc.add({ Type: :Action, S: :URI, URI: "https://example.com" },
                       type: described_class)
      expect(action.scheme).to eq("https")
      expect(action.http?).to be true
      expect(action.mailto?).to be false
    end
  end
end
