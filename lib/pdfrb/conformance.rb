# frozen_string_literal: true

module Pdfrb
  # PDF/A conformance checks (ISO 19005). Subset of constraints on
  # top of ISO 32000-2: no JavaScript, no encryption (A-1), embedded
  # fonts required, XMP metadata required, etc.
  module Conformance
    autoload :PdfA, "pdfrb/conformance/pdf_a"
    autoload :PdfUA, "pdfrb/conformance/pdf_ua"
  end
end
