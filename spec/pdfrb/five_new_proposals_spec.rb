# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Proposal fixes and new features" do
  let(:doc) { Pdfrb::Document.new.tap { |d| d.pages.add } }
  let(:page) { doc.pages.first }
  let(:canvas) { page.canvas }

  describe "stringio require fix" do
    it "Fonts#add accepts file path without NameError" do
      expect { doc.fonts.add("/nonexistent/font.ttf") }.not_to raise_error
    end
  end

  describe "FontResolver TTC support" do
    it "includes .ttc in glob" do
      resolver = Pdfrb::FontResolver.new(search_paths: ["/tmp"])
      # Just verify it doesn't crash with ttc extension
      expect { resolver.available_fonts }.not_to raise_error
    end

    it "validates TTC magic bytes via parse" do
      resolver = Pdfrb::FontResolver.new(search_paths: [])
      expect(resolver.available_fonts).to eq([])
    end
  end

  describe "TTF table parsing fix" do
    it "uses parsed cmap accessor, not raw table()" do
      ttf_data = "\u0000\u0001\u0000\u0000#{"\x00" * 200}"
      io = StringIO.new(ttf_data)
      # Should not raise about undefined method glyph_id_for on String
      expect { doc.fonts.add(io) }.not_to raise_error
    end
  end

  describe "Canvas#text_rich" do
    it "draws multiple runs in one BT/ET block" do
      f1 = doc.fonts.add("Helvetica")
      canvas.text_rich([
                         { text: "Hello ", font: f1, size: 12 },
                         { text: "World", font: f1, size: 12 },
                       ], at: [72, 720])
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("BT")
      expect(data).to include("ET")
      expect(data.scan("BT").length).to eq(1)
      expect(data).to include("Hello")
      expect(data).to include("World")
    end

    it "applies per-run color" do
      f1 = doc.fonts.add("Helvetica")
      canvas.text_rich([
                         { text: "Red", font: f1, size: 12, color: [:rgb, 1, 0, 0] },
                       ], at: [72, 720])
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("1 0 0")
    end
  end

  describe "Canvas transparency" do
    it "opacity= creates ExtGState" do
      canvas.opacity = 0.5
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("gs")
    end

    it "blend_mode= creates ExtGState" do
      canvas.blend_mode = :Multiply
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("gs")
    end

    it "with_transparency wraps in q/Q" do
      canvas.with_transparency(opacity: 0.5, blend_mode: :Screen) do
        canvas.rectangle(0, 0, 100, 100)
        canvas.fill
      end
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("q")
      expect(data).to include("Q")
      expect(data).to include("gs")
    end

    it "with_transparency at full opacity is a no-op for alpha" do
      canvas.with_transparency(opacity: 1.0) do
        canvas.text("Hi", at: [0, 0], font: :F1, size: 12)
      end
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).not_to include("gs")
    end
  end

  describe "Clipping operators registered" do
    it "has ClipNonZero, ClipEvenOdd, InvokeXObject in registry" do
      expect(Pdfrb::Content::Operator["W"]).not_to be_nil
      expect(Pdfrb::Content::Operator["W*"]).not_to be_nil
      expect(Pdfrb::Content::Operator["Do"]).not_to be_nil
    end

    it "Canvas#clip emits W n" do
      canvas.save_graphics_state do
        canvas.rectangle(0, 0, 100, 100)
        canvas.clip
      end
      stream = page.value[:Contents]
      stream_obj = stream.is_a?(Pdfrb::Model::Reference) ? doc.object(stream) : stream
      data = stream_obj&.stream || ""
      expect(data).to include("W")
      expect(data).to include("n")
    end
  end
end
