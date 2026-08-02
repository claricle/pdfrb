# frozen_string_literal: true

module Pdfrb
  # Semantic PDF comparison. Compares two PDFs at the structural level:
  # page count, per-page extracted text, font inventory, image count,
  # outline structure, and metadata. Returns a structured report.
  #
  # Designed for regression testing: "did our render change from
  # yesterday's reference?" Not a pixel diff — that's a separate
  # concern (rasterize + image compare).
  module Compare
    autoload :Report, "pdfrb/compare/report"
    autoload :Comparator, "pdfrb/compare/comparator"

    module_function

    # Compare two PDFs. Accepts bytes, IO, or Document objects.
    #
    # @param left [String, IO, Pdfrb::Document]
    # @param right [String, IO, Pdfrb::Document]
    # @return [Pdfrb::Compare::Report]
    def compare(left, right)
      left_doc = to_document(left)
      right_doc = to_document(right)
      Comparator.new.compare(left_doc, right_doc)
    end

    # Convenience: returns true if the two PDFs are equivalent.
    def equivalent?(left, right)
      compare(left, right).equivalent?
    end

    def to_document(input)
      case input
      when Pdfrb::Document then input
      when ::String then Pdfrb::Document.new(io: StringIO.new(input))
      when IO, StringIO then Pdfrb::Document.new(io: input)
      else raise ArgumentError, "expected String, IO, or Document"
      end
    end
  end
end
