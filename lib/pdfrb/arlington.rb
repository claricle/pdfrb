# frozen_string_literal: true

module Pdfrb
  # Arlington PDF Model integration layer. Loads the vendored TSVs
  # from `data/pdfrb/arlington/<version>/*.tsv` and surfaces them as
  # typed records (`ObjectDefinition` -> `FieldDefinition`).
  #
  # Drives the field metadata on every `Model::Type::*` class via
  # `Dictionary.arlington_object "Name"`. Predicates (`fn:...`) are
  # lexed/parsed/evaluated on demand by the predicate sub-namespace.
  module Arlington
    autoload :Type, "pdfrb/arlington/type"
    autoload :PdfVersion, "pdfrb/arlington/pdf_version"
    autoload :Loader, "pdfrb/arlington/loader"
    autoload :ObjectDefinition, "pdfrb/arlington/object_definition"
    autoload :FieldDefinition, "pdfrb/arlington/field_definition"
    autoload :Predicate, "pdfrb/arlington/predicate"
  end
end
