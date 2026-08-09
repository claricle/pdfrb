# frozen_string_literal: true

module Pdfrb
  module Conformance
    autoload :Rule, "pdfrb/conformance/rule"
    autoload :RuleSet, "pdfrb/conformance/rule"
    autoload :Violation, "pdfrb/conformance/rule"
    autoload :ValidationResult, "pdfrb/conformance/rule"
    autoload :PdfA, "pdfrb/conformance/pdf_a"
    autoload :PdfA4Deep, "pdfrb/conformance/pdf_a4_deep"
    autoload :PdfUA, "pdfrb/conformance/pdf_ua"
    autoload :PdfUA2Deep, "pdfrb/conformance/pdf_ua2_deep"
    autoload :PdfUATaggingDeep, "pdfrb/conformance/pdf_ua_tagging_deep"
    autoload :PdfX, "pdfrb/conformance/pdf_x"
    autoload :PdfVT, "pdfrb/conformance/pdf_vt"
    autoload :Pdf2AF, "pdfrb/conformance/pdf_2_af"
    autoload :Pades, "pdfrb/conformance/pades"
    autoload :Ltv, "pdfrb/conformance/ltv"
    autoload :TaggedPdf, "pdfrb/conformance/tagged_pdf"
    autoload :StructureElements, "pdfrb/conformance/structure_elements"
    autoload :VeraPdfBridge, "pdfrb/conformance/verapdf_bridge"
  end
end
