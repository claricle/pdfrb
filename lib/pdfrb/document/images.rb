# frozen_string_literal: true

require "zlib"

module Pdfrb
  class Document
    # Image facade. +add+ dispatches to +ImageLoader.load+ which
    # auto-detects format from the bytes (JPEG, PNG, or PDF page).
    class Images
      attr_reader :document, :registry

      def initialize(document)
        @document = document
        @registry = {}        # resource name -> image Object
        @next_id = 1
      end

      # Build an Image XObject from +io+ (path, IO, or bytes) and
      # register it in the document's /Resources/XObject. Returns the
      # resource name (e.g. :Im1).
      def add(io, **)
        image = Pdfrb::ImageLoader.load(document, io, **)
        name = next_resource_name
        attach_to_resources(name, image)
        registry[name] = image
        name
      end

      def [](name)
        registry[name]
      end

      def each(&)
        return enum_for(:each) unless block_given?

        registry.each(&)
        self
      end

      private

      def next_resource_name
        sym = :"Im#{@next_id}"
        @next_id += 1
        sym
      end

      def attach_to_resources(name, image)
        ref = Pdfrb::Model::Reference.new(image.oid, image.gen)
        # Page-tree root so every page inherits it (s7.7.3.2).
        root = document.pages.pages_root
        root.value[:Resources] ||= {}
        root.value[:Resources][:XObject] ||= {}
        root.value[:Resources][:XObject][name] = ref
      end
    end
  end
end
