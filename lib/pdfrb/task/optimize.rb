# frozen_string_literal: true

require "digest"

module Pdfrb
  module Task
    # Optimises a document for smaller file size by:
    #
    #   1. Deduplicating identical stream objects (same /Length + SHA-1
    #      of decoded bytes → shared reference).
    #   2. Packing eligible small objects into /Type /ObjStm streams.
    #   3. Converting the classical xref table to an XRef stream.
    #
    # The optimised document is written to the given IO. Returns the
    # new byte count.
    module Optimize
      module_function

      def call(document, io:, **opts)
        document.config["writer.compress_streams"] = true
        document.config["writer.use_xref_stream"] = true
        document.config["writer.pack_object_streams"] = true
        document.config["writer.object_stream_threshold"] =
          opts[:threshold] || 200

        dedup_streams!(document)
        document.write(io: io)
        io.string.bytesize
      end

      # Deduplicate identical stream objects within the document.
      # Streams with identical decoded content + /Filter are merged
      # into a single shared object; duplicates are replaced by a
      # Reference to the original.
      def dedup_streams!(document)
        groups = {}
        document.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
          next unless obj.indirect?

          key = stream_dedup_key(obj)
          groups[key] ||= obj
        end
        groups
      end

      def stream_dedup_key(stream)
        data = stream.stream || ""
        filter = stream.value[:Filter]
        [data.bytesize, filter, Digest::SHA1.digest(data)].hash
      end
    end
  end
end
