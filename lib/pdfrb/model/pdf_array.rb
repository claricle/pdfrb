# frozen_string_literal: true

module Pdfrb
  module Model
    # Wraps a Ruby Array of PDF values. Subclass of Object so it can
    # carry oid/gen when stored as an indirect object. Preserves
    # insertion order and supports type-aware wrapping on access
    # when nested inside a typed Dictionary (field-driven).
    class PdfArray < Pdfrb::Model::Object
      include Enumerable
      extend Cos::ArlingtonBacked

      class << self
        # ArlingtonBacked hook: array TSVs describe positional element
        # types (keys "0", "1", ...), so keep the definition whole
        # rather than merging per-field metadata.
        def apply_arlington_definition(definition)
          @arlington_definition = definition
        end
        private :apply_arlington_definition

        def arlington_definition
          @arlington_definition
        end

        # FieldDefinition for the element at +index+, per the TSV.
        def element_field(index)
          arlington_definition&.field_for(index.to_s)
        end
      end

      def initialize(arr = [], oid: 0, gen: 0, document: nil)
        super(Array(arr), oid: oid, gen: gen, document: document)
      end

      def each(&)
        @value.each(&)
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
