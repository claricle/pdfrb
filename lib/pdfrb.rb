# frozen_string_literal: true

module Pdfrb
  autoload :VERSION, "pdfrb/version"

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

  autoload :Configuration, "pdfrb/configuration"
  autoload :DataDir, "pdfrb/data_dir"
  autoload :PdfConstants, "pdfrb/pdf_constants"
  autoload :PdfVersion, "pdfrb/pdf_version"

  autoload :Source, "pdfrb/source"
  autoload :Model, "pdfrb/model"
  autoload :Arlington, "pdfrb/arlington"
  autoload :Filter, "pdfrb/filter"
  autoload :Content, "pdfrb/content"
  autoload :Encryption, "pdfrb/encryption"
  autoload :DigitalSignature, "pdfrb/digital_signature"

  autoload :Font, "pdfrb/font"
  autoload :FontLoader, "pdfrb/font_loader"
  autoload :FontResolver, "pdfrb/font_resolver"
  autoload :ImageLoader, "pdfrb/image_loader"
  autoload :Image, "pdfrb/image"
  autoload :Task, "pdfrb/task"
  autoload :Color, "pdfrb/color"
  autoload :Annotation, "pdfrb/annotation"
  autoload :Appearance, "pdfrb/appearance"
  autoload :Conformance, "pdfrb/conformance"
  autoload :Validator, "pdfrb/validator"
  autoload :XMP, "pdfrb/xmp"
  autoload :Destination, "pdfrb/destination"
  autoload :Linearization, "pdfrb/linearization"
  autoload :Action, "pdfrb/action"

  autoload :Serializer, "pdfrb/serializer"
  autoload :Writer, "pdfrb/writer"
  autoload :Importer, "pdfrb/importer"
  autoload :XrefSection, "pdfrb/xref_section"
  autoload :Document, "pdfrb/document"

  autoload :Layout, "pdfrb/layout"
  autoload :Composer, "pdfrb/composer"
  autoload :Compare, "pdfrb/compare"
  autoload :TestUtils, "pdfrb/test_utils"
  autoload :CLI, "pdfrb/cli"

  require "logger"
  require "stringio"

  class << self
    # Open a PDF file (path or block over the file handle).
    def open(path, **, &)
      Document.open(path, **, &)
    end

    # Parse PDF bytes/IO into a Document.
    def parse(io, **)
      io = StringIO.new(io.b) if io.is_a?(String)
      Document.new(io: io, **)
    end
  end

  def self.logger
    @logger ||= Logger.new($stderr, level: Logger::WARN)
  end

  def self.logger=(log)
    @logger = log
  end
end
