# frozen_string_literal: true

module Pdfrb
  # In-memory cross-reference section (s7.5.4). Maps oid -> Entry
  # where each Entry is one of:
  #   * :in_use   — at +offset+ in the file, generation +gen+.
  #   * :free     — head of free list (with next-free oid +gen+).
  #   * :compressed — inside ObjStm +obj_stm_oid+ at index +index+.
  class XrefSection
    Entry = Struct.new(:type, :offset, :gen, :obj_stm_oid, :index, keyword_init: true) do
      def in_use?; type == :in_use; end
      def free?; type == :free; end
      def compressed?; type == :compressed; end
    end

    attr_reader :entries, :size

    def initialize(size: 0)
      @entries = {}
      @size = size
    end

    def add_in_use(oid, gen, offset)
      @entries[oid] = Entry.new(type: :in_use, offset: offset, gen: gen)
      @size = [@size, oid + 1].max
    end

    def add_free(oid, gen, next_free)
      @entries[oid] = Entry.new(type: :free, offset: next_free, gen: gen)
    end

    def add_compressed(oid, obj_stm_oid, index)
      @entries[oid] = Entry.new(type: :compressed, obj_stm_oid: obj_stm_oid, index: index)
      @size = [@size, oid + 1].max
    end

    def [](oid)
      @entries[oid]
    end

    def each_entry(&block)
      @entries.each(&block)
    end

    def merge!(other)
      other.entries.each { |oid, e| @entries[oid] = e unless @entries.key?(oid) }
      @size = [@size, other.size].max
      self
    end
  end
end
