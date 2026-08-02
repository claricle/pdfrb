# frozen_string_literal: true

module Pdfrb
  # Cross-document object importer. Deep-copies a value (and any
  # references it transitively reaches) from a source document into
  # this document, allocating fresh oids and rewriting references.
  #
  # Cycle-safe: a "currently being imported" set guards against
  # infinite recursion when objects reference each other.
  class Importer
    attr_reader :target, :mappings

    def initialize(target_document)
      @target = target_document
      @mappings = {}        # source_oid -> target Pdfrb::Model::Object
      @in_progress = {}     # source_oid -> half-built target obj
    end

    # Import +source_value+ (resolved against +source_document+) into
    # the target. Returns the imported value (NOT wrapped in an
    # Object; the caller decides oid assignment via Document#add).
    def import(source_value, source_document)
      case source_value
      when Pdfrb::Model::Reference
        import_reference(source_value, source_document)
      when ::Hash
        import_hash(source_value, source_document)
      when ::Array
        source_value.map { |v| import(v, source_document) }
      when Pdfrb::Model::Object
        import(source_value.value, source_document)
      else
        source_value
      end
    end

    private

    def import_reference(ref, source_doc)
      cached = @mappings[ref.oid]
      return Pdfrb::Model::Reference.new(cached.oid, cached.gen) if cached

      in_progress = @in_progress[ref.oid]
      return Pdfrb::Model::Reference.new(in_progress.oid, in_progress.gen) if in_progress

      source_obj = source_doc.object(ref)
      return nil unless source_obj

      # Reserve the oid up-front so cycles resolve to this stub.
      stub = target.add({}, type: Pdfrb::Model::Cos::Dictionary)
      @in_progress[ref.oid] = stub

      imported_value = import(source_obj.value, source_doc)
      stub.value.replace(imported_value)
      # Streams: copy the raw bytes if source was a Stream.
      if source_obj.is_a?(Pdfrb::Model::Cos::Stream)
        stub_stream!(stub, source_obj)
      end
      @mappings[ref.oid] = stub
      @in_progress.delete(ref.oid)
      Pdfrb::Model::Reference.new(stub.oid, stub.gen)
    end

    def import_hash(hash, source_doc)
      hash.transform_values { |v| import(v, source_doc) }
    end

    def stub_stream!(stub, source)
      # Re-wrap the stub Dictionary as a real Stream carrying the
      # source's bytes; register the new object under the same oid.
      stream_bytes = source.stream.dup
      new_stream = target.wrap(stub.value, type: Pdfrb::Model::Cos::Stream,
                                          oid: stub.oid, gen: stub.gen)
      new_stream.stream = stream_bytes
      target.register_override(new_stream)
    end
  end
end
