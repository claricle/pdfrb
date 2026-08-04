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

  autoload :Source, "pdfrb/source"
  autoload :Model, "pdfrb/model"
  autoload :Arlington, "pdfrb/arlington"
  autoload :Filter, "pdfrb/filter"
  autoload :Content, "pdfrb/content"
  autoload :Encryption, "pdfrb/encryption"
  autoload :DigitalSignature, "pdfrb/digital_signature"

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
  autoload :FontResolver, "pdfrb/font_resolver"
  autoload :ImageLoader, "pdfrb/image_loader"
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
  autoload :Revision, "pdfrb/revision"
  autoload :Revisions, "pdfrb/revisions"
  autoload :XrefSection, "pdfrb/xref_section"
  autoload :Document, "pdfrb/document"

  autoload :Compare, "pdfrb/compare"
  autoload :CLI, "pdfrb/cli"
  require "logger"

  def self.logger
    @logger ||= Logger.new($stderr, level: Logger::WARN)
  end

  def self.logger=(log)
    @logger = log
  end
end
