# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Parity batch 15 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Thread do
    it "exposes first_bead and info" do
      bead = doc.add({ Type: :Bead }, type: Pdfrb::Model::Type::Bead)
      info = doc.add({ Title: "Article" }, type: Pdfrb::Model::Cos::Dictionary)
      thread = doc.add(
        {
          Type: :Thread,
          F: Pdfrb::Model::Reference.new(bead.oid, 0),
          I: Pdfrb::Model::Reference.new(info.oid, 0),
        },
        type: described_class
      )
      expect(thread.type).to eq(:Thread)
      expect(thread.first_bead(doc)).not_to be_nil
      expect(thread.info(doc)).not_to be_nil
    end

    it "returns nil resolvers when refs absent" do
      thread = doc.add({ Type: :Thread }, type: described_class)
      expect(thread.first_bead(doc)).to be_nil
      expect(thread.info(doc)).to be_nil
      expect(thread.metadata(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::Bead do
    it "exposes thread, next, previous, page, rect" do
      page = doc.pages.add
      bead_a = doc.add({ Type: :Bead, R: [0, 0, 100, 100] }, type: described_class)
      bead_b = doc.add(
        {
          Type: :Bead,
          N: Pdfrb::Model::Reference.new(bead_a.oid, 0),
          V: Pdfrb::Model::Reference.new(bead_a.oid, 0),
          P: Pdfrb::Model::Reference.new(page.oid, page.gen),
          R: [10, 10, 200, 200],
        },
        type: described_class
      )
      expect(bead_b.type).to eq(:Bead)
      expect(bead_b.next_bead(doc)).not_to be_nil
      expect(bead_b.previous_bead(doc)).not_to be_nil
      expect(bead_b.page(doc)).not_to be_nil
      expect(bead_b.rect).to eq([10, 10, 200, 200])
    end
  end

  describe Pdfrb::Model::Type::WebCaptureInfo do
    it "exposes version and commands" do
      cmd = doc.add({ URL: "https://example.com" },
                    type: Pdfrb::Model::Type::WebCaptureCommand)
      info = doc.add(
        { V: 1, C: [Pdfrb::Model::Reference.new(cmd.oid, 0)] },
        type: described_class
      )
      expect(info.version).to eq(1)
      commands = info.commands(doc)
      expect(commands.length).to eq(1)
      expect(commands.first.url).to eq("https://example.com")
    end
  end

  describe Pdfrb::Model::Type::WebCaptureCommand do
    it "exposes url, delay, content_type" do
      cmd = doc.add(
        { URL: "https://example.com", L: 5, CT: "text/html" },
        type: described_class
      )
      expect(cmd.url).to eq("https://example.com")
      expect(cmd.delay_seconds).to eq(5)
      expect(cmd.content_type).to eq("text/html")
      expect(cmd.flags).to eq(0)
    end

    it "defaults delay to 1 and CT to form-urlencoded" do
      cmd = doc.add({ URL: "https://example.com" }, type: described_class)
      expect(cmd.delay_seconds).to eq(1)
      expect(cmd.content_type).to eq("application/x-www-form-urlencoded")
    end
  end

  describe Pdfrb::Model::Type::WebCaptureCommandSettings do
    it "exposes get and cookie params" do
      settings = doc.add(
        { G: { q: "test" }, C: { session: "abc" } },
        type: described_class
      )
      expect(settings.get_params[:q]).to eq("test")
      expect(settings.cookie_params[:session]).to eq("abc")
    end
  end

  describe Pdfrb::Model::Type::WebCaptureImageSet do
    it "exposes set_type, id, images" do
      image = doc.add({ Type: :XObject, Subtype: :Image, Width: 1, Height: 1 },
                      type: Pdfrb::Model::Type::XObjectImage)
      set = doc.add(
        {
          Type: :SpiderContentSet, S: :SIS, ID: "set-1",
          O: [Pdfrb::Model::Reference.new(image.oid, 0)]
        },
        type: described_class
      )
      set.stream = ""
      expect(set.type).to eq(:SpiderContentSet)
      expect(set.set_type).to eq(:SIS)
      expect(set.set_id).to eq("set-1")
      expect(set.images(doc).length).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::WebCapturePageSet do
    it "exposes set_type, id, pages" do
      page = doc.pages.add
      set = doc.add(
        {
          Type: :SpiderContentSet, S: :SPS, ID: "pages-1",
          O: [Pdfrb::Model::Reference.new(page.oid, page.gen)]
        },
        type: described_class
      )
      set.stream = ""
      expect(set.set_type).to eq(:SPS)
      expect(set.pages(doc).length).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::TrapRegion do
    it "exposes trap parameters and zones" do
      region = doc.add(
        { TP: "1.0", TZ: [[0, 0, 100, 100]] },
        type: described_class
      )
      expect(region.trap_parameters).to eq("1.0")
      expect(region.trap_zones).to eq([[0, 0, 100, 100]])
    end
  end
end
