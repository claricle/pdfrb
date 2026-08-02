# frozen_string_literal: true

module Pdfrb
  module Model
    # Wraps a Ruby Array of PDF values. Subclass of Object so it can
    # carry oid/gen when stored as an indirect object. Preserves
    # insertion order and supports type-aware wrapping on access
    # when nested inside a typed Dictionary (field-driven).
    class PdfArray < Pdfrb::Model::Object
      include Enumerable

      def initialize(arr = [], oid: 0, gen: 0, document: nil)
        super(Array(arr), oid: oid, gen: gen, document: document)
      end

      def each(&block)
        @value.each(&block)
        self
      end

      def length; @value.length; end
      alias size length

      def empty?; @value.empty?; end

      def [](idx)
        @value[idx]
      end

      def []=(idx, v)
        @value[idx] = v
      end

      def <<(v)
        @value << v
        self
      end

      def push(*items)
        @value.push(*items)
        self
      end

      def delete_at(idx)
        @value.delete_at(idx)
      end

      def to_a
        @value.dup
      end

      def ==(other)
        return @value == other.value if other.is_a?(PdfArray)

        @value == other
      end

      def inspect
        "PdfArray[#{@value.inspect}]"
      end
    end
  end
end
