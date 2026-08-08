# frozen_string_literal: true

require "digest"

module Pdfrb
  module Task
    # Optimises a document for smaller file size by:
    #
    #   1. Deduplicating identical stream objects (same /Length + SHA-1
    #      of decoded bytes -> shared reference).
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

        dedup_streams!(document) unless opts[:dedup] == false
        downsample_images!(document, factor: opts[:downsample_factor]) unless opts[:downsample] == false
        document.write(io: io)
        io.string.bytesize
      end

      # Walk every image XObject and (for FlateDecode-encoded 8-bpc
      # non-palette images) halve each dimension by +factor+ using
      # nearest-neighbour. JPEG/JP2K are skipped — re-encoding them in
      # pure Ruby isn't tractable. Returns the count of images that
      # were modified.
      def downsample_images!(document, factor: 2)
        return 0 unless factor && factor >= 2

        count = 0
        document.each_indirect_object do |obj|
          next unless Pdfrb::Image::Audit.image_xobject?(obj)
          next unless Pdfrb::Image::Downsampler.eligible?(obj)

          changed = Pdfrb::Image::Downsampler.downsample!(obj, factor: factor)
          count += 1 if changed
        end
        count
      end

      # Deduplicate identical stream objects within the document.
      # Streams with identical decoded content + /Filter are merged
      # into a single shared object; duplicates are replaced by a
      # Reference to the canonical one. Returns a Hash of
      # {duplicate_oid => canonical_oid} that was applied.
      def dedup_streams!(document)
        canonical_for = {}
        document.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
          next unless obj.indirect?
          next if obj.value[:Type] == :ObjStm

          key = stream_dedup_key(obj)
          canonical_for[key] ||= obj.oid
        end

        replacements = {}
        document.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
          next unless obj.indirect?
          next if obj.value[:Type] == :ObjStm

          key = stream_dedup_key(obj)
          canonical_oid = canonical_for[key]
          next if canonical_oid == obj.oid

          replacements[obj.oid] = canonical_oid
        end
        apply_replacements(document, replacements)
      end

      def stream_dedup_key(stream)
        data = stream.stream || +""
        filter = stream.value[:Filter]
        [data.bytesize, filter, Digest::SHA1.digest(data)].hash
      end

      # Walk every object's value tree, replacing References whose oid
      # is in +replacements+ with a Reference to the canonical oid.
      # Also clears each replacement source from the document's
      # modified-objects table so the writer doesn't emit it.
      def apply_replacements(document, replacements)
        return replacements if replacements.empty?

        document.each_indirect_object do |obj|
          rewrite_references(obj, replacements)
        end
        replacements.each_key { |oid| document.forget(oid) }
        replacements
      end

      # Recursively rewrite references inside a value. Handles
      # Dictionaries (Hash / Cos::Dictionary), Arrays / PdfArrays,
      # and References. Returns the (possibly new) value.
      def rewrite_references(value, replacements)
        case value
        when Pdfrb::Model::Cos::Dictionary, Pdfrb::Model::Cos::Stream
          rewrite_hash(value.value, replacements)
        when ::Hash
          rewrite_hash(value, replacements)
        when Pdfrb::Model::PdfArray
          rewrite_array(value.value, replacements)
        when ::Array
          rewrite_array(value, replacements)
        when Pdfrb::Model::Reference
          replace_ref(value, replacements)
        else
          value
        end
      end

      def rewrite_hash(hash, replacements)
        hash.each do |k, v|
          hash[k] = rewrite_references(v, replacements)
        end
        hash
      end

      def rewrite_array(arr, replacements)
        arr.each_with_index do |v, i|
          arr[i] = rewrite_references(v, replacements)
        end
        arr
      end

      def replace_ref(ref, replacements)
        canonical = replacements[ref.oid]
        return ref unless canonical

        Pdfrb::Model::Reference.new(canonical, 0)
      end
    end
  end
end
