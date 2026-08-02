# frozen_string_literal: true

# Pdfrb — pure-Ruby PDF library.
#
# Two-direction contract:
#   * "PDF file <=> Model" — parse PDF bytes into a typed Model, serialize
#     a Model back to PDF bytes. Round-trip is the correctness backbone.
#   * "API Builder Input => Model" — Document / Canvas build a typed
#     Model from user intent, which is then serialized.
#
# Pdfrb is deliberately scoped to the PDF byte format. Layout concerns
# (page templates, flows, line breaking, tables, etc.) live in the
# sibling `arroolio` gem.
#
# The PDF object model is sourced directly from the vendored Arlington
# PDF Model TSVs (data/pdfrb/arlington/*.tsv). Field metadata, version
# predicates, and validators stay aligned with ISO 32000-2:2020 by data,
# not by hand-coded mimicry.
#
# Layering (mirrors the sibling postscript gem):
#   Source      — bytes → tokens → COS graph (read direction)
#   Model       — typed domain model (COS values + Type::* semantics)
#   Arlington   — TSV loader + predicate evaluator (drives Model field defs)
#   Filter      — stream filter pipeline (Flate, ASCII-85, LZW, ...)
#   Content     — content-stream operators + Canvas drawing API
#   Serializer  — Model → bytes
#   Writer      — Document → file (xref + trailer assembly)
#   Document    — top-level facade
module Pdfrb
  autoload :VERSION, "pdfrb/version"

  # Errors — every failure mode in the gem subclasses Pdfrb::Error.
  autoload :Error, "pdfrb/error"
  autoload :ParseError, "pdfrb/error"
  autoload :LexError, "pdfrb/error"
  autoload :SyntaxError, "pdfrb/error"
  autoload :MalformedPdfError, "pdfrb/error"
  autoload :SerializeError, "pdfrb/error"
  autoload :FilterError, "pdfrb/error"
  autoload :EncryptionError, "pdfrb/error"
  autoload :UnsupportedVersionError, "pdfrb/error"
  autoload :ValidationError, "pdfrb/error"
  autoload :ObjectReferenceError, "pdfrb/error"

  # Cross-cutting helpers.
  autoload :Configuration, "pdfrb/configuration"
  autoload :DataDir, "pdfrb/data_dir"
  autoload :PdfConstants, "pdfrb/pdf_constants"

  # Sub-namespaces. Each lives in its own file which holds the autoloads
  # for that namespace's children (the "immediate parent" rule).
  autoload :Source, "pdfrb/source"
  autoload :Model, "pdfrb/model"
  autoload :Arlington, "pdfrb/arlington"
  autoload :Filter, "pdfrb/filter"
  autoload :Content, "pdfrb/content"
  autoload :Encryption, "pdfrb/encryption"
  autoload :DigitalSignature, "pdfrb/digital_signature"

  # Eager-load Type::* subclasses so they self-register in the
  # /Type-symbol type_map before any wrap call happens. Without
  # this, the first read of a Catalog wouldn't upgrade to
  # Type::Catalog (because the constant hadn't been autoloaded yet
  # and therefore hadn't called register_type).
  require "pdfrb/model/type/file_trailer"
  require "pdfrb/model/type/catalog"
  require "pdfrb/model/type/info"
  require "pdfrb/model/type/page_tree_node"
  require "pdfrb/model/type/page"
  require "pdfrb/model/type/resources"
  require "pdfrb/model/type/metadata"
  require "pdfrb/model/type/object_stream"
  require "pdfrb/model/type/xref_stream"
  require "pdfrb/model/type/graphics_state_parameter"
  require "pdfrb/model/type/optional_content_group"
  require "pdfrb/model/type/struct_tree_root"
  require "pdfrb/model/type/font_type1"
  require "pdfrb/model/type/annotation"
  require "pdfrb/model/type/action"
  autoload :Font, "pdfrb/font"
  autoload :FontLoader, "pdfrb/font_loader"
  autoload :ImageLoader, "pdfrb/image_loader"
  autoload :Task, "pdfrb/task"

  # Top-level orchestrators.
  autoload :Serializer, "pdfrb/serializer"
  autoload :Writer, "pdfrb/writer"
  autoload :Importer, "pdfrb/importer"
  autoload :Revision, "pdfrb/revision"
  autoload :Revisions, "pdfrb/revisions"
  autoload :XrefSection, "pdfrb/xref_section"
  autoload :Document, "pdfrb/document"

  # CLI (only loaded when invoked via the +pdfrb+ executable; avoids
  # pulling in thor for library-only users).
  autoload :CLI, "pdfrb/cli"
end
