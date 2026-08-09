# frozen_string_literal: true

module Pdfrb
  module Conformance
    autoload :Rule, "pdfrb/conformance/rule"
    autoload :RuleSet, "pdfrb/conformance/rule"
    autoload :Violation, "pdfrb/conformance/rule"
    autoload :ValidationResult, "pdfrb/conformance/rule"
    autoload :PdfA, "pdfrb/conformance/pdf_a"
    autoload :PdfUA, "pdfrb/conformance/pdf_ua"
    autoload :PdfX, "pdfrb/conformance/pdf_x"
    autoload :TaggedPdf, "pdfrb/conformance/tagged_pdf"
    autoload :StructureElements, "pdfrb/conformance/structure_elements"
    autoload :VeraPdfBridge, "pdfrb/conformance/verapdf_bridge"
  end
end
