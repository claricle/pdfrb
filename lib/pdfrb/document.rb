# frozen_string_literal: true

module Pdfrb
  # Top-level PDF document facade. Owns:
  #   * The IO it was read from (or nil for in-memory).
  #   * An oid -> Object table for new/modified objects.
  #   * A wrap() pipeline that upgrades raw Hashes to typed
  #     Dictionary subclasses based on /Type or an explicit type.
  #   * On read: an XrefSection + ObjectReader for lazy resolution.
  #   * A revisions stack (TODO 30 — incremental updates).
  class Document
    autoload :Pages, "pdfrb/document/pages"
    autoload :Fonts, "pdfrb/document/fonts"
    autoload :Metadata, "pdfrb/document/metadata"
    autoload :Images, "pdfrb/document/images"
    autoload :Files, "pdfrb/document/files"
    autoload :Destinations, "pdfrb/document/destinations"
    autoload :Annotations, "pdfrb/document/annotations"
    autoload :Outline, "pdfrb/document/outline"
    autoload :FormXObject, "pdfrb/document/form_xobject"
    autoload :AssociatedFiles, "pdfrb/document/associated_files"
    autoload :Colors, "pdfrb/document/colors"
    autoload :Display, "pdfrb/document/display"
    autoload :Form, "pdfrb/document/form"
    autoload :GraphicsState, "pdfrb/document/graphics_state"
    autoload :Layers, "pdfrb/document/layers"
    autoload :Portfolio, "pdfrb/document/portfolio"
    autoload :Structure, "pdfrb/document/structure"
    autoload :Shadings, "pdfrb/document/shadings"
    autoload :OutputIntents, "pdfrb/document/output_intents"
    autoload :Info, "pdfrb/document/info"
    autoload :PageLabels, "pdfrb/document/page_labels"
    autoload :Stamps, "pdfrb/document/stamps"

    def initialize(io: nil, config: {})
      Pdfrb::Model::Type.eager_load!
      @config = Configuration.new(config)
      @io = io
      @objects = {}        # oid -> Pdfrb::Model::Object (modified or new)
      @next_oid = 1
      @listeners = {}      # message_name -> [Proc]
      @xref = nil
      @object_reader = nil
      @version = "1.4"
      @empty_trailer = nil

      if io
        read_from_io(io)
      else
        seed_empty_structure
      end
    end

    attr_reader :config, :io, :xref, :version, :next_oid

    def self.open(path, **opts)
      if block_given?
        File.open(path, "rb") { |f| yield new(io: f, **opts) }
      else
        bytes = File.binread(path)
        require "stringio"
        new(io: StringIO.new(bytes), **opts)
      end
    end

    def wrap(data, type: nil, oid: 0, gen: 0)
      target_class = resolve_target_class(data, type)
      value = unwrap_value(data)
      if target_class <= Pdfrb::Model::Object
        target_class.new(value, oid: oid, gen: gen, document: self)
      else
        target_class.new(value)
      end
    end

    def add(value, type: nil)
      oid = allocate_oid
      obj = wrap(value, type: type, oid: oid, gen: 0)
      register(obj)
      obj
    end

    # Resolve a Reference to its Object. New/modified objects take
    # precedence over xref-loaded ones; otherwise consult the
    # ObjectReader (which caches per oid).
    def object(reference)
      return reference unless reference.is_a?(Pdfrb::Model::Reference)

      modified = @objects[reference.oid]
      return modified if modified
      return nil if @object_reader.nil?

      @object_reader.load_oid(reference.oid)
    end
    alias dereference object

    def register_listener(message, &block)
      (@listeners[message] ||= []) << block
    end

    def dispatch_message(message, *args)
      return unless @listeners.key?(message)

      @listeners[message].each { |blk| blk.call(*args) }
    end

    # ---- Facade accessors (Phase 13) ----
    # Each returns a memoised helper object that knows how to mutate
    # this document. Defined under Pdfrb::Document::*.

    def pages
      @pages ||= Document::Pages.new(self)
    end

    def fonts
      @fonts ||= Document::Fonts.new(self)
    end

    def images
      @images ||= Document::Images.new(self)
    end

    def files
      @files ||= Document::Files.new(self)
    end

    def metadata
      @metadata ||= Document::Metadata.new(self)
    end

    def destinations
      @destinations ||= Document::Destinations.new(self)
    end

    def annotations
      @annotations ||= Document::Annotations.new(self)
    end

    def outline
      @outline ||= Document::Outline.new(self)
    end

    def structure; @structure ||= Document::Structure.new(self); end

    def form; @form ||= Document::Form.new(self); end

    def shadings; @shadings ||= Document::Shadings.new(self); end

    def colors; @colors ||= Document::Colors.new(self); end

    def graphics_state; @graphics_state ||= Document::GraphicsState.new(self); end

    def layers; @layers ||= Document::Layers.new(self); end

    def associated_files; @associated_files ||= Document::AssociatedFiles.new(self); end

    def portfolio; @portfolio ||= Document::Portfolio.new(self); end

    def output_intents; @output_intents ||= Document::OutputIntents.new(self); end

    def page_labels; @page_labels ||= Document::PageLabels.new(self); end

    def stamps; @stamps ||= Document::Stamps.new(self); end

    def info; @info ||= Document::Info.new(self); end

    def display; @display ||= Document::Display.new(self); end

    def xmp
      return @xmp if @xmp

      packet = load_xmp_packet
      return nil unless packet

      title = metadata[:Title]
      packet.title = title if title
      author = metadata[:Author]
      packet.author = author if author
      @xmp = packet
    end

    def load_xmp_packet
      Pdfrb::XMP::Packet.new
    rescue LoadError
      nil
    end

    def version=(v); @version = v.to_s; end

    def create_form_xobject(name: nil, bbox: nil, matrix: nil)
      FormXObject.new(self, name: name, bbox: bbox, matrix: matrix)
    end

    # Replace an indirect object in the @objects table. Used by the
    # Importer when promoting a Dictionary stub to a Stream (so cycles
    # resolve correctly). Idempotent.
    def register_override(obj)
      @objects[obj.oid] = obj
    end

    # Drop a modified/new object from the in-memory table so it's no
    # longer emitted by the writer. Used by Task::Optimize when a
    # stream has been deduplicated against a canonical sibling.
    # Returns the dropped object (or nil if not present).
    def forget(oid)
      @objects.delete(oid)
    end

    # Write this document to +path+ (or any IO via +io:).
    def write(path = nil, io: nil)
      target = io || (path && File.open(path, "wb"))
      raise ArgumentError, "write needs a path or io:" unless target

      Pdfrb::Writer.write(self, target)
      target.close if path && io.nil? && target.is_a?(IO)
      self
    end

    # Convenience accessor for the document Catalog dict. Loads from
    # trailer's /Root, which itself is loaded lazily from the xref.
    def trailer
      return @trailer if defined?(@trailer) && @trailer

      @trailer = read_trailer
    end

    def catalog
      return @catalog if defined?(@catalog) && @catalog

      ref = trailer ? trailer[:Root] : nil
      return nil unless ref

      @catalog = object(ref)
    end

    # Yield every indirect object in this document: modified/new ones
    # first (they shadow loaded ones), then every loaded entry the
    # xref knows about.
    def each_indirect_object
      return enum_for(:each_indirect_object) unless block_given?

      seen = Set.new
      @objects.each_value do |obj|
        next unless obj.indirect?

        seen << obj.oid
        yield obj
      end
      return if @xref.nil?

      @xref.entries.each_key do |oid|
        next if seen.include?(oid)
        next if oid.zero?

        obj = object(Pdfrb::Model::Reference.new(oid, 0))
        next if obj.nil? || !obj.indirect?

        yield obj
      end
    end

    private

    def allocate_oid
      oid = @next_oid
      @next_oid += 1
      oid
    end

    def register(obj)
      @objects[obj.oid] = obj
    end

    def read_from_io(io)
      version = Pdfrb::Source::HeaderReader.read(io)
      @version = version if version
      sxref = Pdfrb::Source::TrailerReader.startxref_offset(io)
      return unless sxref

      @xref, @trailer_dict = load_xref_and_trailer(io, sxref)
      @object_reader = Pdfrb::Source::ObjectReader.new(self, @xref) if @xref
    end

    def load_xref_and_trailer(io, sxref)
      xref, trailer = load_single_xref(io, sxref)
      return [nil, nil] unless xref && trailer

      # Follow /Prev chain for incremental updates. Earlier entries
      # fill gaps; later entries take precedence (already in xref).
      prev_offset = trailer[:Prev]
      while prev_offset
        prev_xref, prev_trailer = load_single_xref(io, prev_offset)
        break unless prev_xref

        xref.merge!(prev_xref)
        prev_offset = prev_trailer && prev_trailer[:Prev]
      end

      [xref, trailer]
    end

    def load_single_xref(io, sxref)
      actual_xref_pos = find_xref_keyword(io, sxref)
      if actual_xref_pos
        xref = Pdfrb::Source::XrefTableReader.read(io, actual_xref_pos)
        trailer = read_trailer_dict_after_xref(io)
        return [xref, trailer]
      end

      # Try as XRef stream (PDF 1.5+).
      io.seek(sxref, IO::SEEK_SET)
      tok = Pdfrb::Source::Tokenizer.new(io)
      parser = Pdfrb::Source::Parser.new(tok, document: self)
      obj = parser.parse_indirect_object rescue nil
      if obj.is_a?(Pdfrb::Model::Cos::Stream) && obj[:Type] == :XRef
        xref = Pdfrb::Source::XrefStreamReader.read(obj, self)
        [xref, obj.value]
      else
        # Last resort: recovery.
        recover_or_raise(Pdfrb::ParseError.new("cannot locate xref at #{sxref}"))
        [nil, nil]
      end
    rescue Pdfrb::ParseError => e
      recover_or_raise(e)
    end

    # Search for the "xref" keyword near +offset+. Real PDFs have
    # startxref values that drift (19-byte entries, generator bugs).
    # Must exclude false matches inside "startxref\nNNNN\n%%EOF".
    def find_xref_keyword(io, offset)
      # First try the exact offset.
      io.seek(offset, IO::SEEK_SET)
      return offset if io.gets&.strip == "xref"

      # Search backwards for "\nxref\n" (newline-anchored to avoid
      # matching "startxref") within 2KB before the offset.
      search_start = [offset - 2048, 0].max
      io.seek(search_start, IO::SEEK_SET)
      chunk = io.read(offset - search_start + 10)
      # Find the last "\nxref\n" — the \n prefix ensures we don't
      # match the "xref" inside "startxref".
      pos = chunk.rindex("\nxref\n")
      return search_start + pos + 1 if pos

      # If not found with \n prefix, try from byte 0 (the xref might
      # be at the very start of the search chunk with no \n before it).
      pos = chunk.rindex("xref\n")
      # Verify it's not inside "startxref".
      if pos && pos > 4 && chunk.byteslice(pos - 4, 5) == "start"
        pos = chunk.rindex("xref\n", pos - 1)
      end
      pos ? search_start + pos : nil
    end

    def read_trailer_dict_after_xref(io)
      # XrefTableReader already consumed up to and including the
      # "trailer" keyword line; skip any blank lines then parse the
      # dict that follows.
      while (line = io.gets)
        break unless line.strip.empty?
      end
      io.seek(-line.bytesize, IO::SEEK_CUR) if line
      tok = Pdfrb::Source::Tokenizer.new(io)
      parser = Pdfrb::Source::Parser.new(tok, document: self)
      parser.parse_dict
    end

    def read_trailer
      return @trailer_dict if defined?(@trailer_dict) && @trailer_dict

      @empty_trailer
    end

    def seed_empty_structure
      pages = add({ Type: :Pages, Kids: [], Count: 0 })
      catalog = add({ Type: :Catalog, Pages: Pdfrb::Model::Reference.new(pages.oid, 0) })
      @catalog = catalog
      @empty_trailer = { Size: @next_oid, Root: Pdfrb::Model::Reference.new(catalog.oid, 0) }
    end

    def recover_or_raise(error)
      recover = @config["source.recover_malformed"]
      raise error unless recover

      recovered = Pdfrb::Source::Recovery.rebuild_xref(@io)
      @xref = recovered
      @object_reader = Pdfrb::Source::ObjectReader.new(self, recovered)
      nil
    end

    def resolve_target_class(data, requested)
      return requested if requested.is_a?(Class)
      return data.class if data.is_a?(Pdfrb::Model::Object) && requested.nil? && typed_object?(data)

      value = unwrap_value(data)
      if value.is_a?(::Hash)
        sym = value[:Type]
        if sym
          mapped = Pdfrb::Model::Cos::Dictionary.lookup_type(sym)
          return mapped if mapped
        end
      end
      default_class_for(value)
    end

    def typed_object?(obj)
      obj.class != Pdfrb::Model::Object && obj.class != Pdfrb::Model::Cos::Dictionary
    end

    def unwrap_value(data)
      data.is_a?(Pdfrb::Model::Object) ? data.value : data
    end

    def default_class_for(value)
      case value
      when ::Hash then Pdfrb::Model::Cos::Dictionary
      when ::Array then Pdfrb::Model::PdfArray
      else Pdfrb::Model::Object
      end
    end
  end
end
