# frozen_string_literal: true

require "digest"
require "zlib"

module Pdfrb
  # Writes a Document to an IO as a complete PDF file: header,
  # indirect objects, xref section, trailer.
  #
  # Two modes:
  #   * +write+ (default) — full rewrite; assign oids to new objects,
  #     emit every object the document references.
  #   * +write_incremental+ — append a new revision to an existing
  #     byte stream. Only valid when the document was opened from an
  #     IO; the original bytes are preserved verbatim, and a new
  #     xref + trailer are appended with /Prev pointing back.
  class Writer
    DEFAULT_VERSION = "1.4"

    attr_reader :document, :io, :serializer

    def initialize(document, io)
      @document = document
      @io = io
      @serializer = Serializer.new(
        compress_streams: document.config["writer.compress_streams"],
        compress_min_size: document.config["writer.compress_min_size"],
        **serializer_encrypter_opts
      )
      @xref_offsets = {}
    end

    # Build the encrypter option for the Serializer from the document's
    # /Encrypt dict. If the document isn't encrypted, returns empty hash.
    # The SecurityHandler's encrypt_data method becomes the Serializer's
    # encrypter, which encrypts string/stream payloads per-object.
    def serializer_encrypter_opts
      # Use a pre-configured handler if the document provides one
      # (e.g., set by the encryption CLI).
      handler = document.config["encryption.handler"]
      return { encrypter: handler } if handler

      trailer = document.trailer
      return {} unless trailer

      encrypt_ref = trailer[:Encrypt]
      return {} unless encrypt_ref

      encrypt_dict = document.resolve(encrypt_ref)
      return {} unless encrypt_dict

      handler = Pdfrb::Encryption::StandardSecurityHandler.new(
        Encrypt: encrypt_dict.value,
        ID: trailer[:ID]
      )
      password = document.config["encryption.password"] || ""
      handler.verify_user_password(password)

      { encrypter: handler }
    rescue StandardError
      {}
    end

    def self.write(document, io)
      new(document, io).write
    end

    def self.write_incremental(document, io)
      new(document, io).write_incremental
    end

    def write
      @io.binmode
      @io.truncate(0) if @io.is_a?(StringIO)
      write_header
      dispatch_before_write

      use_stream = document.config["writer.use_xref_stream"]
      pack_objstm = document.config["writer.pack_object_streams"]

      packed = pack_objstm ? pack_object_streams : {}

      each_indirect_object do |obj|
        next if packed.key?(obj.oid)

        @xref_offsets[obj.oid] = @io.pos
        @io << @serializer.serialize_indirect(obj)
      end

      xref_pos = if use_stream
                   write_xref_stream(packed)
                 else
                   write_xref
                 end
      if use_stream
        write_xref_stream_trailer(xref_pos)
      else
        write_trailer(xref_pos)
      end
      @io.flush
      self
    end

    # Append a new revision to the original byte stream. Requires the
    # document to have been opened from an IO (so we can copy its
    # original bytes verbatim) and the IO the writer is given is the
    # target output.
    def write_incremental
      raise Pdfrb::Error, "incremental write requires a source IO" unless document.io

      @io.binmode
      # Copy the original bytes verbatim.
      document.io.seek(0, IO::SEEK_SET)
      @io << document.io.read
      dispatch_before_write
      # Emit only the modified objects.
      document.each_indirect_object do |obj|
        next unless obj.indirect?

        @xref_offsets[obj.oid] = @io.pos
        @io << @serializer.serialize_indirect(obj)
      end
      xref_pos = write_xref(prev: previous_xref_offset)
      write_trailer(xref_pos, prev: previous_xref_offset)
      @io.flush
      self
    end

    private

    def write_header
      @io << "%PDF-#{version}\n"
      @io << "%\xE2\xE3\xCF\xD3\n"
    end

    def write_xref(prev: nil)
      pos = @io.pos
      oids = @xref_offsets.keys.sort
      max_oid = oids.max || 0
      @io << "xref\n"
      @io << "0 #{max_oid + 1}\n"
      # Each entry must be EXACTLY 20 bytes per s7.5.4: 10-digit offset,
      # 1 space, 5-digit gen, 1 space, 1-char type, 2-byte EOL (CR+LF).
      # No trailing space before the EOL — that was the bug.
      @io << format("%010d %05d f\r\n", 0, 65_535)
      (1..max_oid).each do |oid|
        offset = @xref_offsets[oid]
        if offset
          @io << format("%010d %05d n\r\n", offset, 0)
        else
          @io << format("%010d %05d f\r\n", 0, 0)
        end
      end
      pos
    end

    # Emit an XRef stream (PDF 1.5+). The xref data is encoded as
    # binary in a /Type /XRef stream object. /W [1 3 1] gives
    # 5 bytes per entry: type (1), offset_or_objstm_oid (3),
    # gen_or_index (1).
    def write_xref_stream(packed = {})
      require "zlib"

      oids = (@xref_offsets.keys + packed.keys).sort
      max_oid = oids.max || 0
      size = max_oid + 1

      w_type = 1
      w_field2 = 3
      w_field3 = 1

      data = build_xref_stream_data(max_oid, packed, w_type, w_field2, w_field3)
      compressed = ::Zlib::Deflate.deflate(data)

      xref_stream_oid = document.next_oid || (max_oid + 1)
      stream_offset = @io.pos
      header = "#{xref_stream_oid} 0 obj\n"

      trailer_fields = trailer_hash_for_stream
      dict_str = @serializer.serialize(
        **trailer_fields,
        Type: :XRef,
        Size: size,
        W: [w_type, w_field2, w_field3],
        Filter: :FlateDecode,
        Length: compressed.bytesize
      )
      @io << header
      @io << dict_str
      @io << "\nstream\n"
      @io << compressed
      @io << "\nendstream\nendobj\n"

      stream_offset
    end

    # Build the binary xref stream body. Always emits max_oid + 1
    # entries (one per oid 0..max_oid) so the reader's per-oid index
    # stays aligned. Gaps from dedup'd oids become free entries.
    def build_xref_stream_data(max_oid, packed, w_type, w_field2, w_field3)
      data = +""
      (0..max_oid).each do |oid|
        entry = xref_entry_for(oid, packed)
        data << encode_xref_entry(entry[0], entry[1], entry[2],
                                  w_type, w_field2, w_field3)
      end
      data
    end

    # Returns [type, field2, field3] for the xref entry of +oid+.
    def xref_entry_for(oid, packed)
      return [0, 0, 0] if oid.zero?

      if @xref_offsets.key?(oid)
        [1, @xref_offsets[oid], 0]
      elsif packed.key?(oid)
        objstm_oid, index = packed[oid]
        [2, objstm_oid, index]
      else
        [0, 0, 0]
      end
    end

    def write_xref_stream_trailer(xref_pos)
      @io << "startxref\n#{xref_pos}\n%%EOF\n"
    end

    def encode_xref_entry(type, f2, f3, w1, w2, w3)
      entry = +""
      entry << [type].pack("C") if w1.positive?
      entry << [f2].pack("N").byteslice(-w2, w2) if w2.positive?
      entry << [f3].pack("C") if w3 == 1
      entry
    end

    # Pack eligible objects into /Type /ObjStm streams.
    # Returns a Hash { oid => [objstm_oid, index] }.
    def pack_object_streams
      threshold = document.config["writer.object_stream_threshold"] || 200
      packed = {}

      candidates = []
      each_indirect_object do |obj|
        next if obj.is_a?(Pdfrb::Model::Cos::Stream)
        next if obj.value[:Type] == :XRef
        next if obj.value[:Type] == :ObjStm

        serialized = @serializer.serialize(obj.value.is_a?(::Hash) ? obj.value : obj)
        next if serialized.bytesize > threshold

        candidates << [obj.oid, serialized]
      end

      return packed if candidates.empty?

      header_pairs = +""
      body = +""
      candidates.each_with_index do |(oid, serialized), _index|
        offset = body.bytesize
        header_pairs << "#{oid} #{offset}\n"
        body << serialized << "\n"
      end

      n = candidates.length
      first = header_pairs.bytesize
      combined = header_pairs + body
      compressed = ::Zlib::Deflate.deflate(combined)

      objstm = document.add(
        { Type: :ObjStm, N: n, First: first, Length: compressed.bytesize },
        type: Pdfrb::Model::Cos::Stream
      )
      objstm.stream = compressed
      objstm.value[:Filter] = :FlateDecode

      packed_offset = @io.pos
      @io << @serializer.serialize_indirect(objstm)

      candidates.each_with_index do |(oid, _serialized), index|
        packed[oid] = [objstm.oid, index]
      end

      @xref_offsets[objstm.oid] = packed_offset
      packed
    end

    def write_trailer(xref_pos, prev: nil)
      root = document.catalog
      root_ref = root && root.is_a?(Pdfrb::Model::Object) && root.indirect? ?
                   root.ref : nil
      size = [(@xref_offsets.keys.max || 0) + 1, document.next_oid || 1].max

      existing = document.trailer || {}
      trailer_hash = {}
      existing.each do |k, v|
        next if %i[Size Root Prev XRefStm].include?(k)

        trailer_hash[k] = v
      end
      trailer_hash[:Size] = size
      trailer_hash[:Root] = root_ref if root_ref
      trailer_hash[:Prev] = prev if prev

      @io << "trailer\n"
      @io << @serializer.serialize(trailer_hash)
      @io << "\nstartxref\n#{xref_pos}\n%%EOF\n"
    end

    def previous_xref_offset
      @previous_xref_offset ||= begin
        # Re-scan the source's startxref. Same logic as TrailerReader
        # but the source IO is the document's.
        Pdfrb::Source::TrailerReader.startxref_offset(document.io)
      end
    end

    def dispatch_before_write
      document.dispatch_message(:before_write)
      compress_content_streams if document.config["writer.compress_streams"]
      normalize_page_resources
      seed_file_identifier
    end

    # PDF/A (ISO 19005-2, 6.2.2) requires every page whose content
    # references resources to carry an EXPLICIT /Resources entry;
    # inherited-only resources fail validation. Copy the page-tree
    # root's resources onto pages that lack their own.
    def normalize_page_resources
      root = document.catalog && document.object(document.catalog.value[:Pages])
      return unless root.is_a?(Pdfrb::Model::Cos::Dictionary)

      inherited = root.value[:Resources]
      return if inherited.nil?

      Array(root.value[:Kids]).each do |kid_ref|
        page = document.resolve(kid_ref)
        next unless page.is_a?(Pdfrb::Model::Cos::Dictionary)
        next if page.value.key?(:Resources)

        page.value[:Resources] = inherited
      end
    end

    # ISO 32000-1 s14.4: the trailer shall carry a /ID file
    # identifier. Derived deterministically from the catalog
    # serialization + object census so identical content yields
    # identical identifiers.
    def seed_file_identifier
      existing = document.trailer || {}
      return if existing[:ID]

      fingerprint = +@serializer.serialize(document.catalog.value)
      each_indirect_object { |obj| fingerprint << obj.oid.to_s << "," }
      digest = ::Digest::MD5.digest(fingerprint)
      existing[:ID] = [digest, digest]
    end

    def version
      v = document.version || DEFAULT_VERSION
      detect_version_features(v)
    end

    def each_indirect_object
      document.each_indirect_object { |obj| yield obj }
    end

    def root_reference
      root = document.catalog
      return nil unless root && root.indirect?

      root.ref
    end

    def trailer_hash_for_stream
      hash = {}
      ref = root_reference
      hash[:Root] = ref if ref

      existing = document.trailer || {}
      existing.each do |k, v|
        next if %i[Size Root Prev XRefStm Type W Filter Length].include?(k)

        hash[k] = v
      end
      [(@xref_offsets.keys.max || 0) + 1,
       document.next_oid || 1].max
      hash
    end

    def detect_version_features(current)
      catalog = document.catalog
      return current unless catalog

      v = current
      if (catalog.value[:AF] || catalog.value[:Collection]) && Pdfrb::PdfVersion.compare(v, "2.0").negative?
        v = "2.0"
      end
      if catalog.value[:OCProperties] && Pdfrb::PdfVersion.compare(v, "1.5").negative?
        v = "1.5"
      end
      document.version = v
      v
    end

    def compress_content_streams
      require "zlib"
      document.each_indirect_of(Pdfrb::Model::Cos::Stream) do |obj|
        next if obj.value[:Filter]
        next unless obj.stream
        next if obj.value[:Type] == :Metadata

        min = document.config["writer.compress_min_size"] || 50
        next if obj.stream.bytesize < min

        compressed = ::Zlib::Deflate.deflate(obj.stream)
        obj.stream = compressed
        obj.value[:Filter] = :FlateDecode
        obj.value[:Length] = compressed.bytesize
      end
    end
  end
end
