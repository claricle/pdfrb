# frozen_string_literal: true

module Pdfrb
  class Document
    # Attached-files facade. Embeds files as /Type /EmbeddedFile streams
    # referenced by /Type /FileSpec dicts, stored in the Catalog's
    # /Names /EmbeddedFiles name tree.
    #
    # Per PDF 2.0 App Note 002, files can also be associated with
    # specific PDF objects (pages, annotations) via the /AF array.
    class Files
      include Enumerable

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Embed a file. Returns the /FileSpec object.
      #
      # @param data [String, IO] raw file contents (binary).
      # @param name [String] filename (used for /F and /UF).
      # @param mime_type [String, nil] MIME type for /Subtype on EmbeddedFile.
      # @param description [String, nil] human-readable /Desc.
      # @param relationship [Symbol, nil] :Source, :Data, :Alternative,
      #   :Supplement, :EncryptedPayload (PDF 2.0 /AF relationship).
      # @param associated_object [Pdfrb::Model::Object, nil] if set,
      #   adds this file to that object's /AF array.
      # @return [Pdfrb::Model::Cos::Dictionary] the FileSpec object.
      def add(data, name:, mime_type: nil, description: nil,
              relationship: nil, associated_object: nil)
        raw = read_data(data)

        ef_stream = @document.add(
          { Type: :EmbeddedFile, Subtype: mime_type },
          type: Pdfrb::Model::Cos::Stream
        )
        ef_stream.stream = raw

        filespec = @document.add(
          {
            Type: :FileSpec,
            UF: name.to_s,
            EF: { UF: ef_stream.ref,
                  F: ef_stream.ref },
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        filespec.value[:F] = name.to_s if name.to_s.ascii_only?
        filespec.value[:Desc] = description if description

        register_in_names(name.to_s, filespec)

        if associated_object
          add_to_af(associated_object, filespec, relationship)
        end

        filespec
      end

      def each
        return enum_for(:each) unless block_given?

        names_array = embedded_files_names_array
        return self unless names_array

        names_array.each_slice(2) do |name, ref|
          resolved = @document.resolve(ref)
          yield(name.to_s, resolved) if resolved
        end
        self
      end

      def [](name)
        find { |n, _spec| n == name.to_s }&.last
      end

      def count
        to_a.length
      end

      def empty?
        embedded_files_names_array.nil?
      end

      private

      def read_data(data)
        case data
        when ::String then data.dup.force_encoding(Encoding::BINARY)
        when ::IO, StringIO then data.read.dup.force_encoding(Encoding::BINARY)
        else data.to_s.dup.force_encoding(Encoding::BINARY)
        end
      end

      def register_in_names(name, filespec)
        catalog = @document.catalog
        names = catalog.value[:Names] ||= {}
        ef_tree = names[:EmbeddedFiles] ||= {}
        names_array = ef_tree[:Names] ||= []
        names_array << name
        names_array << filespec.ref
      end

      def embedded_files_names_array
        catalog = @document.catalog
        return nil unless catalog

        names = catalog.value[:Names]
        return nil unless names

        ef_tree = names[:EmbeddedFiles]
        return nil unless ef_tree

        ef_tree[:Names]
      end

      def add_to_af(target, filespec, relationship)
        ref = filespec.ref
        af_entry = if relationship
                     { Type: :AssociatedFile, AFRelationship: relationship,
                       File: ref }
                   else
                     ref
                   end
        target.value[:AF] ||= []
        target.value[:AF] << af_entry
      end
    end
  end
end
