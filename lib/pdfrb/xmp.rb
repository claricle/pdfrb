# frozen_string_literal: true

module Pdfrb
  # XMP (Extensible Metadata Platform) metadata. XMP is XML-based
  # metadata embedded in PDF as a /Metadata stream on the Catalog.
  #
  # Uses lutaml-model for declarative serialization — never hand-rolled.
  # XMP schemas (Dublin Core, PDF, XMP basic) are lutaml-model classes
  # with attribute declarations and XML mapping blocks.
  module XMP
    autoload :Packet, "pdfrb/xmp/packet"
    autoload :Schemas, "pdfrb/xmp/schemas"
  end
end
