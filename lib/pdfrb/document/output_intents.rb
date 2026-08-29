# frozen_string_literal: true

module Pdfrb
  class Document
    # Output Intents facade. An output intent declares the intended
    # output device color profile (ICC) so that downstream processors
    # can render colors consistently. Required for PDF/X.
    #
    # /OutputIntents is an array on the Catalog. Each entry has:
    #   /Type /OutputIntent
    #   /S /GTS_PDFA1 (for PDF/A) or /GTS_PDFX (for PDF/X)
    #   /OutputConditionIdentifier — registry name (e.g. "FOGRA39")
    #   /OutputCondition — human-readable description
    #   /RegistryName — e.g. "http://www.color.org"
    #   /DestOutputProfile — ICC profile stream reference
    class OutputIntents
      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Add an output intent referencing an ICC profile stream.
      # @param icc_stream_ref [Pdfrb::Model::Reference] ICC profile stream.
      # @param identifier [String] e.g. "FOGRA39", "CGATS TR 001".
      # @param condition [String] human-readable description.
      # @param registry [String] URL of the color registry.
      # @param subtype [Symbol] :GTS_PDFA1 or :GTS_PDFX.
      # @return [Pdfrb::Model::Cos::Dictionary] the output intent dict.
      def add(icc_stream_ref, identifier:, condition: nil,
              registry: nil, subtype: :GTS_PDFX)
        intent = document.add(
          {
            Type: :OutputIntent,
            S: subtype,
            OutputConditionIdentifier: identifier,
            OutputCondition: condition,
            RegistryName: registry,
            DestOutputProfile: icc_stream_ref,
          }.compact,
          type: Pdfrb::Model::Cos::Dictionary
        )
        catalog = document.catalog
        intents = catalog.value[:OutputIntents]
        ref = intent.ref
        if intents.nil?
          catalog.value[:OutputIntents] = [ref]
        elsif intents.is_a?(::Array)
          intents << ref
        else
          catalog.value[:OutputIntents] = [intents, ref]
        end
        intent
      end

      # Convenience: embed an ICC profile and register as output intent.
      def embed_icc(icc_bytes, identifier:, condition: nil,
                     registry: nil, subtype: :GTS_PDFX)
        profile = Pdfrb::Color::ICCProfile.new(icc_bytes)
        stream = document.add(
          { **profile.stream_dictionary_fields,
            Length: profile.raw_data.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = profile.raw_data
        ref = stream.ref
        add(ref, identifier: identifier, condition: condition, registry: registry, subtype: subtype)
      end

      # Enumerate output intents.
      def each(&block)
        intents = document.catalog.value[:OutputIntents]
        return enum_for(:each) unless block
        return self unless intents

        intents.each do |ref|
          obj = document.resolve(ref)
          yield obj if obj
        end
        self
      end

      def count
        intents = document.catalog.value[:OutputIntents]
        return 0 unless intents

        intents.is_a?(::Array) ? intents.length : 1
      end
    end
  end
end
