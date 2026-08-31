# frozen_string_literal: true

module Pdfrb
  module Source
    # Resolves Model::Reference values to Model::Object instances by
    # consulting the document's XrefSection. In-use entries seek and
    # parse the indirect object at the recorded offset. Compressed
    # entries defer to ObjectStreamReader.
    #
    # Caches resolved objects per document.
    class ObjectReader
      attr_reader :document, :xref

      def initialize(document, xref)
        @document = document
        @xref = xref
        @cache = {}
        @objstm_cache = {}
      end

      def load(reference)
        load_oid(reference.oid)
      end

      def load_oid(oid)
        return @cache[oid] if @cache.key?(oid)

        entry = xref[oid]
        return nil if entry.nil? || entry.free?

        obj = case entry.type
              when :in_use then decrypt_loaded(parse_at(entry.offset, oid, entry.gen), entry.gen)
              when :compressed then load_from_objstm(entry.obj_stm_oid, entry.index, oid)
              end
        @cache[oid] = obj
        obj
      end

      # The single funnel for read-side decryption (s7.6.1): strings
      # in the object's dictionaries and the stream payload decrypt
      # with the per-object key as the object enters the Model.
      # Objects inside object streams need no separate treatment —
      # only the containing ObjStm stream is encrypted — and the
      # /Encrypt dictionary is exempt (s7.6.3).
      def decrypt_loaded(obj, gen)
        return obj if obj.nil?
        # The exemption check must precede handler construction:
        # building the handler resolves the /Encrypt dict through
        # this same funnel, which would recurse before the memo is
        # set.
        return obj if Pdfrb::Encryption.exempt_object?(document, obj)

        handler = document.encryption.reader_handler
        return obj if handler.nil?

        Pdfrb::Encryption::ValueStrings.decrypt!(obj.value, obj.oid, gen, handler)
        if obj.is_a?(Pdfrb::Model::Cos::Stream) && obj.stream
          obj.stream = handler.decrypt_stream(obj.stream, obj.oid, gen)
        end
        obj
      end

      def clear_cache
        @cache.clear
        @objstm_cache.clear
      end

      private

      def parse_at(offset, expected_oid, expected_gen)
        # Try exact offset first (quiet — if it fails, scan nearby).
        obj = try_parse_at(offset, expected_oid, expected_gen, quiet: true)
        return obj if obj

        # Real-world PDFs frequently have xref offsets that are off
        # by a few bytes (CRLF→LF conversion, generator bugs,
        # incremental edits). Scan ±256 bytes for the right oid/gen.
        scan_range = (-256..256)
        scan_range.each do |delta|
          next if delta.zero?
          candidate = offset + delta
          next if candidate.negative?

          obj = try_parse_at(candidate, expected_oid, expected_gen, quiet: true)
          return obj if obj
        end

        # Last resort: scan the whole file for "N G obj" pattern.
        recover_parse(expected_oid, expected_gen)
      end

      def try_parse_at(offset, expected_oid, expected_gen, quiet: false)
        document.io.seek(offset, IO::SEEK_SET)
        tokenizer = Tokenizer.new(document.io)
        parser = Parser.new(tokenizer, document: document)
        obj = parser.parse_indirect_object
        if obj.oid == expected_oid && obj.gen == expected_gen
          upgrade_to_typed(obj)
        else
          nil
        end
      rescue StandardError => e
        quiet ? nil : raise
      end

      def recover_parse(expected_oid, expected_gen)
        pattern = /#{expected_oid}\s+#{expected_gen}\s+obj\b/
        document.io.seek(0, IO::SEEK_SET)
        data = document.io.read
        match = data.match(pattern)
        raise Pdfrb::MalformedPdfError.new(
          "cannot find object #{expected_oid} #{expected_gen} anywhere in file",
          recovered: false
        ) unless match

        offset = match.begin(0)
        try_parse_at(offset, expected_oid, expected_gen)
      end

      # Re-wrap the parsed object via document.wrap so a Type::*
      # subclass (registered for the dict's /Type) is used instead
      # of the base Cos::Dictionary. Streams stay Streams.
      def upgrade_to_typed(obj)
        return obj unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)

        if obj.is_a?(Pdfrb::Model::Cos::Stream)
          target_class = stream_class_for(obj) || Pdfrb::Model::Cos::Stream
          replacement = document.wrap(obj.value, type: target_class,
                                             oid: obj.oid, gen: obj.gen)
          replacement.stream = obj.stream
          replacement
        else
          document.wrap(obj.value, oid: obj.oid, gen: obj.gen)
        end
      end

      def stream_class_for(stream_obj)
        sym = stream_obj.value[:Type]
        mapped = sym && Pdfrb::Model::Cos::Dictionary.lookup_type(sym)
        mapped if mapped && mapped <= Pdfrb::Model::Cos::Stream
      end

      def load_from_objstm(objstm_oid, index, expected_oid)
        objstm = @objstm_cache[objstm_oid] ||= ObjectStreamReader.read(load_oid(objstm_oid), document)
        pair = objstm[index]
        return nil unless pair

        # ObjectStreamReader returns [oid, value] pairs. Unpack and
        # wrap as a typed Object so type-dispatch (Catalog, Pages,
        # etc.) works the same as for uncompressed objects.
        _oid, value = pair
        document.wrap(value, oid: expected_oid, gen: 0)
      end
    end
  end
end
