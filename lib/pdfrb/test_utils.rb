# frozen_string_literal: true

module Pdfrb
  # Test utilities for downstream projects and our own specs.
  # Provides helpers for creating minimal PDFs, loading fixtures,
  # and round-tripping documents in tests.
  module TestUtils
    module_function

    # Build a minimal valid PDF Document with one blank page.
    # @param size [Array<Float, Float>] page dimensions in points.
    # @return [Pdfrb::Document]
    def minimal_document(size: [612, 792])
      doc = Pdfrb::Document.new
      page = doc.pages.add
      page.value[:MediaBox] = [0, 0, size[0], size[1]]
      doc
    end

    # Build a minimal PDF byte string with one blank page.
    # @param size [Array<Float, Float>] page dimensions in points.
    # @return [String] PDF bytes (binary encoded).
    def minimal_pdf(size: [612, 792])
      require "stringio"
      io = StringIO.new
      minimal_document(size: size).write(io: io)
      io.string
    end

    # Load a fixture file from a relative path under spec/fixtures.
    # @param relative_path [String] e.g., "images/test.png".
    # @return [String] binary contents.
    def load_fixture(relative_path)
      path = fixture_path(relative_path)
      raise "fixture not found: #{path}" unless File.exist?(path)

      File.binread(path)
    end

    # Resolve a fixture path under spec/fixtures.
    # @param relative_path [String] e.g., "pdfs/sample.pdf".
    # @return [String] absolute path.
    def fixture_path(relative_path)
      File.expand_path(File.join("spec", "fixtures", relative_path))
    end

    # Round-trip a Document through serialize → parse and return the
    # re-parsed Document. Useful for verifying write correctness.
    # @param document [Pdfrb::Document] the source document.
    # @return [Pdfrb::Document] re-parsed.
    def roundtrip(document)
      require "stringio"
      io = StringIO.new
      document.write(io: io)
      Pdfrb::Document.new(io: StringIO.new(io.string))
    end

    # Write a Document to a String.
    # @param document [Pdfrb::Document]
    # @return [String] binary PDF bytes.
    def document_to_string(document)
      require "stringio"
      io = StringIO.new
      document.write(io: io)
      io.string
    end

    # Assert that two PDF byte strings have the same page count.
    # @param left [String] first PDF bytes.
    # @param right [String] second PDF bytes.
    # @return [Boolean]
    def same_page_count?(left, right)
      count_pages(left) == count_pages(right)
    end

    # Count pages in a PDF byte string.
    # @param pdf_bytes [String]
    # @return [Integer]
    def count_pages(pdf_bytes)
      Pdfrb::Document.new(io: StringIO.new(pdf_bytes)).pages.count
    end

    # Generate a one-page PDF with a single text string.
    # @param text [String] the text to render.
    # @param font [Symbol] font resource name.
    # @param size [Integer] point size.
    # @return [String] binary PDF bytes.
    def pdf_with_text(text, font: :Helvetica, size: 12)
      require "stringio"
      doc = Pdfrb::Document.new
      doc.pages.add.canvas.text(text, at: [50, 750], font: font, size: size)
      io = StringIO.new
      doc.write(io: io)
      io.string
    end

    # Capture Pdfrb logger output during a block. Returns the captured
    # string. Useful for asserting on warnings.
    # @yield block to execute.
    # @return [String] captured log output.
    def capture_log
      require "stringio"
      original = Pdfrb.logger
      buffer = StringIO.new
      Pdfrb.logger = Logger.new(buffer)
      yield
      buffer.string
    ensure
      Pdfrb.logger = original
    end
  end
end
