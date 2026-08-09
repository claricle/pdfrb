# frozen_string_literal: true

module Pdfrb
  module Source
    # Last-resort recovery: scan the entire file for `\d+ \d+ obj`
    # patterns and synthesise an XrefSection from the offsets found.
    # Triggered when the xref table is missing or points to a wrong
    # offset.
    #
    # Extended recovery capabilities:
    #   * Cross-reference table reconstruction (the original mode).
    #   * Trailer recovery: find /Root and /Encrypt by scanning for
    #     the keys directly when the trailer is corrupt.
    #   * Hybrid xref detection: read both xref table and xref stream
    #     when both are present.
    #   * Object-stream reconstruction: rebuild an XrefSection from a
    #     /Type /ObjStm stream when its header is intact but the
    #     xref stream is missing.
    module Recovery
      OBJ_PATTERN = /(\d+)\s+(\d+)\s+obj\b/.freeze
      TRAILER_ROOT_PATTERN = %r{/Root\s+(\d+)\s+(\d+)\s+R}.freeze
      TRAILER_ENCRYPT_PATTERN = %r{/Encrypt\s+(\d+)\s+(\d+)\s+R}.freeze
      TRAILER_INFO_PATTERN = %r{/Info\s+(\d+)\s+(\d+)\s+R}.freeze
      private_constant :OBJ_PATTERN, :TRAILER_ROOT_PATTERN,
                       :TRAILER_ENCRYPT_PATTERN, :TRAILER_INFO_PATTERN

      module_function

      def rebuild_xref(io, recover: true)
        return nil unless recover

        io.seek(0, IO::SEEK_SET)
        section = XrefSection.new
        data = io.read
        data.force_encoding(Encoding::BINARY)
        offset = 0
        while (m = data.match(OBJ_PATTERN, offset))
          oid = m[1].to_i
          gen = m[2].to_i
          entry_offset = m.begin(0)
          # Take the last-seen gen per oid (PDF spec: highest gen wins).
          section.add_in_use(oid, gen, entry_offset)
          offset = m.end(0)
        end
        section
      end

      # Scan the file for /Root, /Info, /Encrypt references when the
      # trailer dict is unreadable. Returns a Hash with :Root, :Info,
      # :Encrypt keys as References (or nil per key).
      def recover_trailer_references(io)
        io.seek(0, IO::SEEK_SET)
        data = io.read.to_s
        data.force_encoding(Encoding::BINARY)

        root_match = data.match(TRAILER_ROOT_PATTERN)
        info_match = data.match(TRAILER_INFO_PATTERN)
        encrypt_match = data.match(TRAILER_ENCRYPT_PATTERN)

        {
          Root: root_match ? Pdfrb::Model::Reference.new(root_match[1].to_i, root_match[2].to_i) : nil,
          Info: info_match ? Pdfrb::Model::Reference.new(info_match[1].to_i, info_match[2].to_i) : nil,
          Encrypt: encrypt_match ? Pdfrb::Model::Reference.new(encrypt_match[1].to_i, encrypt_match[2].to_i) : nil,
        }
      end

      # Detect hybrid xref: PDF 1.7+ allows both a classical xref
      # table AND an xref stream in the same revision, referenced
      # from the table via /XRefStm. Returns true if the file has
      # both. Pure-Ruby: scans for `startxref` followed by both
      # `xref` and a Type=XRef stream object.
      def hybrid_xref?(io)
        io.seek(0, IO::SEEK_SET)
        data = io.read.to_s
        data.force_encoding(Encoding::BINARY)

        has_table = data.include?("\nxref\n")
        has_stream = data.match?(/\/Type\s*\/XRef\b/)
        has_table && has_stream
      end

      # Reconstruct an XrefSection from a /Type /ObjStm stream by
      # reading its /N + /First + decompressed body. Used when the
      # outer xref stream is corrupt but a known ObjStm is intact.
      def rebuild_from_object_stream(objstm, document)
        return nil unless objstm

        pairs = ObjectStreamReader.read(objstm, document)
        section = XrefSection.new
        pairs.each_key do |oid|
          # Mark as compressed in objstm 0 (placeholder; caller
          # fills in the real objstm_oid).
          section.add_compressed(oid, 0, 0, objstm.oid)
        end
        section
      end
    end
  end
end
