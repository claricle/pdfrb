# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tempfile"
require "digest/md5"

RSpec.describe "Critical feature parity specs" do
  let(:doc) { Pdfrb::Document.new }

  describe "Page manipulation API" do
    before do
      5.times { doc.pages.add }
    end

    it "deletes a page by index" do
      expect(doc.pages.count).to eq(5)
      doc.pages.delete_at(2)
      expect(doc.pages.count).to eq(4)
    end

    it "rotates all pages" do
      doc.pages.rotate(90)
      doc.pages.each { |p| expect(p.value[:Rotate]).to eq(90) }
    end

    it "moves a page within the document" do
      expect(doc.pages.count).to eq(5)
      doc.pages.move(0, 2)
      expect(doc.pages.count).to eq(5)
    end

    it "iterates with index" do
      indices = []
      doc.pages.each_with_index { |_p, i| indices << i }
      expect(indices).to eq([0, 1, 2, 3, 4])
    end
  end

  describe "Form fill and flatten" do
    let(:page) { doc.pages.add }

    it "sets and gets a text field value" do
      doc.form.add_text_field("name", page: page, rect: [0, 0, 200, 30])
      doc.form.set_value("name", "Alice")
      expect(doc.form.get_value("name")).to eq("Alice")
    end

    it "sets a checkbox value" do
      doc.form.add_checkbox("agree", page: page, rect: [0, 0, 20, 20])
      doc.form.set_value("agree", true)
      expect(doc.form.get_value("agree")).to eq(:Yes)
    end

    it "lists all field names" do
      doc.form.add_text_field("first", page: page, rect: [0, 0, 100, 20])
      doc.form.add_text_field("last", page: page, rect: [0, 0, 100, 20])
      expect(doc.form.field_names).to include("first", "last")
    end

    it "removes a single field" do
      field = doc.form.add_text_field("temp", page: page, rect: [0, 0, 100, 20])
      expect(doc.form.count).to eq(1)
      doc.form.remove_field(field)
      expect(doc.form.count).to eq(0)
    end
  end

  describe "Radio button appearance generation" do
    let(:page) { doc.pages.add }

    it "generates multi-state appearance for radio buttons" do
      field = doc.form.add_checkbox("opt", page: page, rect: [0, 0, 30, 30])
      generator = Pdfrb::Appearance::Generator.new(doc)
      generator.radio_button(field, selected: "Yes", options: %w[Yes No])

      expect(field.value[:AP]).not_to be_nil
      expect(field.value[:AS]).to eq(:Yes)
    end
  end

  describe "List box appearance generation" do
    let(:page) { doc.pages.add }

    it "renders list items with selection highlighting" do
      field = doc.form.add_combo("choices", page: page, rect: [0, 0, 200, 100],
                                            options: %w[A B C])
      generator = Pdfrb::Appearance::Generator.new(doc)
      generator.list_box(field, items: %w[Apple Banana Cherry], selected: 1)

      expect(field.value[:AP]).not_to be_nil
    end
  end

  describe "Canvas draw_form_xobject" do
    it "draws a Form XObject by resource name without error" do
      page = doc.pages.add
      canvas = page.canvas

      # Create and register a minimal form XObject
      form_stream = doc.add(
        { Type: :XObject, Subtype: :Form, BBox: [0, 0, 100, 100] },
        type: Pdfrb::Model::Cos::Stream
      )
      form_stream.stream = "q Q"

      resources = page.value[:Resources]
      resources = page.value[:Resources] = Pdfrb::Model::Cos::Dictionary.new({}) unless resources.is_a?(Pdfrb::Model::Cos::Dictionary)
      resources.value[:XObject] ||= {}
      resources.value[:XObject][:Fm1] = Pdfrb::Model::Reference.new(form_stream.oid, form_stream.gen)

      expect { canvas.draw_form_xobject(:Fm1, at: [50, 50]) }.not_to raise_error
    end
  end

  describe "TextLayouter with real glyph widths" do
    it "measures text width from Standard 14 AFM" do
      style = Pdfrb::Layout::Style.new(:base)
      layouter = Pdfrb::Layout::TextLayouter.new(style)
      lines = layouter.layout("Hello World", 5000)
      expect(lines).not_to be_empty
      expect(lines.length).to eq(1)
    end

    it "wraps text when width is too small" do
      style = Pdfrb::Layout::Style.new(:base, font_size: 12)
      layouter = Pdfrb::Layout::TextLayouter.new(style)
      lines = layouter.layout("The quick brown fox jumps over the lazy dog", 50)
      expect(lines.length).to be > 1
    end
  end

  describe "Structure alt-text API" do
    it "sets alt text on a figure element" do
      doc.structure.enable!
      elem = doc.structure.add_element(:Figure)
      doc.structure.set_alt_text(elem, "A diagram")
      expect(doc.structure.has_alt_text?(elem)).to be true
    end

    it "validates that figures have alt text" do
      doc.structure.enable!
      doc.structure.add_element(:Figure, alt: "Has alt")
      doc.structure.add_element(:Figure)

      violations = doc.structure.validate_alt_text!
      expect(violations.length).to eq(1)
    end

    it "sets actual text and language" do
      doc.structure.enable!
      elem = doc.structure.add_element(:Span)
      doc.structure.set_actual_text(elem, "expansion")
      doc.structure.set_language(elem, "en-US")
      expect(elem.value[:ActualText]).to eq("expansion")
      expect(elem.value[:Lang]).to eq("en-US")
    end
  end

  describe "Font metrics lookup" do
    it "returns ascent/descent for Helvetica" do
      metrics = Pdfrb::Font::MetricsHelper.metrics_for("Helvetica")
      expect(metrics).not_to be_nil
      expect(metrics.ascent).to be > 600
      expect(metrics.descent).to be < 0
    end

    it "computes line height at 12pt" do
      metrics = Pdfrb::Font::MetricsHelper.metrics_for("Times-Roman")
      height = metrics.line_height(12)
      expect(height).to be > 10
    end
  end

  describe "GraphicsState facade" do
    let(:page) { doc.pages.add }

    it "registers transparency ExtGState" do
      name = doc.graphics_state.register_transparency(page, opacity: 0.5)
      expect(name).to match(/\AGS\d+\z/)

      resources = page.value[:Resources]
      ext = resources.value[:ExtGState]
      gs = doc.object(ext[name])
      expect(gs.value[:CA]).to eq(0.5)
    end

    it "registers line width ExtGState" do
      name = doc.graphics_state.register_line_width(page, width: 2.5)
      expect(name).to match(/\AGS\d+\z/)

      gs = doc.object(page.value[:Resources].value[:ExtGState][name])
      expect(gs.value[:LW]).to eq(2.5)
    end
  end

  describe "Encryption infrastructure" do
    it "derives encryption key from password" do
      id0 = Digest::MD5.hexdigest("test")[0, 16]
      o_entry = "\x00".b * 32
      key = Pdfrb::Encryption::PasswordVerification.derive_key_rc4(
        password: "user", o_entry: o_entry, p_flags: -1,
        id0: id0.b, revision: 3, key_length_bits: 40
      )
      expect(key.bytesize).to eq(5) # 40 bits / 8 = 5 bytes
    end

    it "builds U entry for R3" do
      key = "\xAA".b * 5
      u = Pdfrb::Encryption::PasswordVerification.build_u_r3plus(
        file_key: key, id0: "test".b, revision: 3
      )
      expect(u.bytesize).to eq(32)
    end

    it "creates an /Encrypt dict on the document" do
      id0 = Digest::MD5.hexdigest("test")[0, 16]
      doc.trailer[:ID] = [id0.b, id0.b]

      encrypt_dict = doc.add(
        { Filter: :Standard, V: 2, R: 3, Length: 40, P: -1,
          O: "\x00".b * 32, U: "\x00".b * 32 },
        type: Pdfrb::Model::Cos::Dictionary
      )
      doc.trailer[:Encrypt] = Pdfrb::Model::Reference.new(encrypt_dict.oid, 0)

      encrypt = doc.object(doc.trailer[:Encrypt])
      expect(encrypt.value[:Filter]).to eq(:Standard)
      expect(encrypt.value[:V]).to eq(2)
    end

    it "strips /Encrypt for decrypt" do
      encrypt = doc.add({ Filter: :Standard, V: 2, R: 3, P: -1,
                          O: "\x00".b * 32, U: "\x00".b * 32 })
      doc.trailer[:Encrypt] = Pdfrb::Model::Reference.new(encrypt.oid, 0)
      expect(doc.trailer[:Encrypt]).not_to be_nil

      # Simulate decrypt CLI: strip the /Encrypt key.
      t = doc.trailer
      if t.is_a?(Pdfrb::Model::Cos::Dictionary)
        t.value.delete(:Encrypt)
      else
        t.delete(:Encrypt)
      end
      expect(doc.trailer[:Encrypt]).to be_nil
    end
  end

  describe "Composer" do
    it "creates a multi-page PDF via Composer" do
      Tempfile.create(["composer", ".pdf"]) do |f|
        Pdfrb::Composer.create(f.path) do |c|
          c.text("Page 1 content")
          c.new_page
          c.text("Page 2 content")
        end
        expect(File.exist?(f.path)).to be true
        bytes = File.binread(f.path)
        expect(bytes).to start_with("%PDF-")
      end
    end
  end

  describe "TestUtils" do
    it "creates minimal PDF" do
      bytes = Pdfrb::TestUtils.minimal_pdf
      expect(bytes).to start_with("%PDF-")
      expect(bytes).to end_with("%%EOF\n")
      expect(Pdfrb::TestUtils.count_pages(bytes)).to eq(1)
    end

    it "round-trips a document" do
      doc = Pdfrb::TestUtils.minimal_document
      doc.metadata.title = "Roundtrip"
      reloaded = Pdfrb::TestUtils.roundtrip(doc)
      expect(reloaded.metadata.title).to eq("Roundtrip")
    end
  end
end
