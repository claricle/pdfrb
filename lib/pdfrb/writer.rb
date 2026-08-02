# frozen_string_literal: true

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
        compress_min_size: document.config["writer.compress_min_size"]
      )
      @xref_offsets = {} # oid -> byte offset
    end

    def self.write(document, io)
      new(document, io).write
    end

    def self.write_incremental(document, io)
      new(document, io).write_incremental
    end

    def write
      @io.binmode
      @io.truncate(0) if @io.respond_to?(:truncate)
      write_header
      dispatch_before_write
      each_indirect_object do |obj|
        @xref_offsets[obj.oid] = @io.pos
        @io << @serializer.serialize_indirect(obj)
      end
      xref_pos = write_xref
      write_trailer(xref_pos)
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
      document.instance_variable_get(:@objects).each_value do |obj|
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
      @io << sprintf("0000000000 65535 f \r\n")
      (1..max_oid).each do |oid|
        offset = @xref_offsets[oid]
        if offset
          @io << sprintf("%010d %05d n \r\n", offset, 0)
        else
          @io << sprintf("0000000000 00000 f \r\n")
        end
      end
      pos
    end

    def write_trailer(xref_pos, prev: nil)
      root = document.catalog
      root_ref = root && root.respond_to?(:indirect?) && root.indirect? ?
                   Pdfrb::Model::Reference.new(root.oid, root.gen) : nil
      size = [(@xref_offsets.keys.max || 0) + 1, document.instance_variable_get(:@next_oid) || 1].max

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
    end

    def version
      document.version || DEFAULT_VERSION
    end

    def each_indirect_object
      document.each_indirect_object { |obj| yield obj }
    end
  end
end
