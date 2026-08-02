# frozen_string_literal: true

module Pdfrb
  # Pdfrb domain model. Two layers:
  #
  # * COS (Common Object Syntax) — the literal PDF value types:
  #   Boolean, Integer, Real, String, Name, Null, Array, Dictionary,
  #   Stream, Reference. Lives under Model::Cos.
  #
  # * Type — semantic PDF object types (Catalog, Page, Font, ...).
  #   Each is a Dictionary subclass whose field metadata is sourced
  #   from the vendored Arlington TSVs. Lives under Model::Type.
  #
  # Both directions flow through Model:
  #   "PDF file <=> Model"     parse/serialize target
  #   "API Builder => Model"   Document/Canvas/Composer build into Model
  module Model
    autoload :Object, "pdfrb/model/object"
    autoload :Reference, "pdfrb/model/reference"
    autoload :PdfArray, "pdfrb/model/pdf_array"
    autoload :Rectangle, "pdfrb/model/rectangle"
    autoload :Matrix, "pdfrb/model/matrix"
    autoload :Date, "pdfrb/model/date"
    autoload :Cos, "pdfrb/model/cos"
    autoload :Type, "pdfrb/model/type"
  end
end
