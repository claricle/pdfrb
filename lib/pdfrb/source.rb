# frozen_string_literal: true

module Pdfrb
  # Reading layer: PDF bytes -> Tokenizer -> Parser -> COS object
  # graph -> ObjectReader resolves References via xref -> Document.
  #
  # Same layering concept as `postscript/source/`: a byte-level
  # state-machine Tokenizer feeds a recursive-descent Parser that
  # emits Model values. References are stored as +Model::Reference+
  # values and resolved lazily via the owning Document's ObjectReader.
  module Source
    autoload :Token, "pdfrb/source/token"
    autoload :Tokenizer, "pdfrb/source/tokenizer"
    autoload :Parser, "pdfrb/source/parser"
    autoload :HeaderReader, "pdfrb/source/header_reader"
    autoload :TrailerReader, "pdfrb/source/trailer_reader"
    autoload :XrefTableReader, "pdfrb/source/xref_table_reader"
    autoload :XrefStreamReader, "pdfrb/source/xref_stream_reader"
    autoload :ObjectReader, "pdfrb/source/object_reader"
    autoload :ObjectStreamReader, "pdfrb/source/object_stream_reader"
    autoload :Recovery, "pdfrb/source/recovery"
    autoload :LinearizationDetection, "pdfrb/source/linearization_detection"
  end
end
