# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Type depth — comprehensive coverage" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Catalog do
    let(:catalog) do
      doc.add({ Type: :Catalog, PageLayout: :TwoColumnLeft,
                PageMode: :UseOutlines, MarkInfo: { Marked: true },
                Lang: "en-US" },
              type: Pdfrb::Model::Type::Catalog)
    end

    it "exposes page-layout and page-mode predicates" do
      expect(catalog.single_page_layout?).to be false
      expect(catalog.two_column_layout?).to be true
      expect(catalog.use_outlines_mode?).to be true
      expect(catalog.use_thumbs_mode?).to be false
    end

    it "reports tagged state" do
      expect(catalog.tagged?).to be true
    end

    it "exposes language" do
      expect(catalog.lang).to eq("en-US")
    end
  end

  describe Pdfrb::Model::Type::PageTreeNode do
    let(:root) do
      doc.add({ Type: :Pages, Kids: [], Count: 0 },
              type: Pdfrb::Model::Type::PageTreeNodeRoot)
    end

    it "is recognized as the root" do
      expect(root.root?).to be true
      expect(root.leaf?).to be false
    end

    it "has zero pages" do
      expect(root.page_count).to eq(0)
      expect(root.pages).to eq([])
    end
  end

  describe Pdfrb::Model::Type::Resources do
    let(:resources) do
      doc.add({ Font: { F1: :Helvetica },
                ColorSpace: { CS1: :DeviceRGB },
                ProcSet: [:PDF, :Text] },
              type: Pdfrb::Model::Type::Resources)
    end

    it "lists names per resource category" do
      expect(resources.font_names).to eq([:F1])
      expect(resources.color_space_names).to eq([:CS1])
    end

    it "checks procset membership" do
      expect(resources.has_procset?(:PDF)).to be true
      expect(resources.has_procset?(:ImageC)).to be false
    end

    it "is not empty when it has fonts" do
      expect(resources.empty?).to be false
    end
  end

  describe Pdfrb::Model::Type::XObjectImage do
    let(:image) do
      doc.add({ Type: :XObject, Subtype: :Image,
                Width: 2, Height: 2, BitsPerComponent: 8,
                ColorSpace: :DeviceRGB },
              type: Pdfrb::Model::Type::XObjectImage)
    end

    it "exposes geometry" do
      expect(image.width).to eq(2)
      expect(image.height).to eq(2)
      expect(image.bits_per_component).to eq(8)
    end

    it "computes components per color space" do
      expect(image.components).to eq(3)
    end

    it "computes bytes per row" do
      expect(image.bytes_per_row).to eq(6)
    end

    it "is not masked by default" do
      expect(image.masked?).to be false
      expect(image.has_soft_mask?).to be false
    end
  end

  describe Pdfrb::Model::Type::XObjectForm do
    let(:form) do
      doc.add({ Type: :XObject, Subtype: :Form,
                BBox: [0, 0, 100, 100],
                Matrix: [1, 0, 0, 1, 0, 0] },
              type: Pdfrb::Model::Type::XObjectForm)
    end

    it "exposes bbox and matrix" do
      bbox = form.bbox
      expect([bbox.llx, bbox.lly, bbox.urx, bbox.ury]).to eq([0.0, 0.0, 100.0, 100.0])
      expect(form.form_type).to eq(1)
    end

    it "detects identity matrix" do
      expect(form.identity_matrix?).to be true
    end

    it "is not a transparency group by default" do
      expect(form.transparency_group?).to be false
    end
  end

  describe Pdfrb::Model::Type::OutputIntent do
    let(:intent) do
      doc.add({ Type: :OutputIntent, S: :GTS_PDFA1,
                OutputConditionIdentifier: "sRGB" },
              type: Pdfrb::Model::Type::OutputIntent)
    end

    it "classifies as PDF/A" do
      expect(intent.pdfa?).to be true
      expect(intent.pdfx?).to be false
    end

    it "exposes output condition identifier" do
      expect(intent.output_condition_identifier).to eq("sRGB")
    end
  end

  describe Pdfrb::Model::Type::OptionalContentGroup do
    let(:ocg) do
      doc.add({ Type: :OCG, Name: "Layer 1", Intent: [:View, :Print] },
              type: Pdfrb::Model::Type::OptionalContentGroup)
    end

    it "decodes intent flags" do
      expect(ocg.view_intent?).to be true
      expect(ocg.print_intent?).to be true
      expect(ocg.export_intent?).to be false
    end
  end

  describe Pdfrb::Model::Type::GraphicsStateParameter do
    let(:gsp) do
      doc.add({ Type: :ExtGState, LW: 2.0, LC: 1, Font: [:F1, 12] },
              type: Pdfrb::Model::Type::GraphicsStateParameter)
    end

    it "exposes graphics state fields" do
      expect(gsp.line_width).to eq(2.0)
      expect(gsp.line_cap).to eq(1)
    end

    it "deconstructs Font array" do
      expect(gsp.font_name).to eq(:F1)
      expect(gsp.font_size).to eq(12)
    end

    it "reports font presence" do
      expect(gsp.has_font?).to be true
    end
  end

  describe Pdfrb::Model::Type::OutlineItem do
    let(:item) do
      doc.add({ Title: "Chapter 1", F: 3, Count: 2 },
              type: Pdfrb::Model::Type::OutlineItem)
    end

    it "decodes style flags" do
      expect(item.bold?).to be true
      expect(item.italic?).to be true
    end

    it "reports open state from positive count" do
      expect(item.open?).to be true
      expect(item.child_count).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::StructElem do
    let(:elem) do
      doc.add({ Type: :StructElem, S: :H1, Alt: "Heading text" },
              type: Pdfrb::Model::Type::StructElem)
    end

    it "classifies as heading" do
      expect(elem.heading?).to be true
      expect(elem.block_level?).to be true
    end

    it "exposes alt text" do
      expect(elem.alt_text).to eq("Heading text")
      expect(elem.has_alt_text?).to be true
    end
  end

  describe Pdfrb::Model::Type::EncryptionStandard do
    let(:enc) do
      doc.add({ Filter: :Standard, V: 5, R: 6, Length: 256, P: -1,
                O: "\x00" * 48, U: "\x00" * 48, EncryptMetadata: false },
              type: Pdfrb::Model::Type::EncryptionStandard)
    end

    it "detects AES-256" do
      expect(enc.aes?).to be true
      expect(enc.rc4?).to be false
    end

    it "tracks metadata encryption" do
      expect(enc.metadata_encrypted?).to be false
    end

    it "computes key length" do
      expect(enc.key_length_bytes).to eq(32)
    end
  end

  describe Pdfrb::Model::Type::Info do
    let(:info) do
      doc.add({ Title: "Report", Author: "Alice",
                CreationDate: "D:20260101120000+00'00'" },
              type: Pdfrb::Model::Type::Info)
    end

    it "exposes bibliographic fields" do
      expect(info.title).to eq("Report")
      expect(info.author).to eq("Alice")
    end

    it "parses creation date" do
      expect(info.creation_time&.year).to eq(2026)
    end
  end

  describe Pdfrb::Model::Type::ActionSubmitForm do
    let(:action) do
      doc.add({ Type: :Action, S: :SubmitForm, F: "https://example.com",
                Flags: 4 },
              type: Pdfrb::Model::Type::ActionSubmitForm)
    end

    it "decodes submit-format flags" do
      expect(action.url).to eq("https://example.com")
      expect(action.export_format?).to be true
      expect(action.get_method?).to be false
    end
  end

  describe Pdfrb::Model::Type::AFFileSpecification do
    let(:spec) do
      doc.add({ Type: :Filespec, F: "data.xml", AFRelationship: :Data },
              type: Pdfrb::Model::Type::AFFileSpecification)
    end

    it "exposes AF relationship" do
      expect(spec.af_relationship).to eq(:Data)
      expect(spec.data?).to be true
      expect(spec.source?).to be false
    end
  end
end
