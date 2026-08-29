# frozen_string_literal: true

module Pdfrb
  module Model
    # Base wrapper for every PDF value (direct or indirect). Carries
    # the indirect-reference metadata (oid, gen) and a back-reference
    # to the owning Document for lazy resolution.
    #
    # The wrapped +value+ is the raw Ruby representation:
    #   Boolean  -> true / false
    #   Integer  -> Integer
    #   Real     -> Float
    #   Name     -> Symbol
    #   String   -> String (UTF-8 for text, BINARY for bytes)
    #   Null     -> nil
    #   Array    -> Array or PdfArray
    #   Dict     -> Hash or Dictionary
    #   Stream   -> Stream (subclass of Dictionary)
    #   Ref      -> Reference
    class Object
      attr_reader :value, :oid, :gen, :document

      def initialize(value, oid: 0, gen: 0, document: nil)
        @value = value
        @oid = oid.to_i
        @gen = gen.to_i
        @document = document
      end

      # The indirect reference denoting this object. The single
      # seam for "a reference to this" — callers never construct
      # Reference.new(obj.oid, obj.gen) by hand.
      def ref
        Pdfrb::Model::Reference.new(oid, gen)
      end

      # True when this object is referenced indirectly (oid > 0).
      def indirect?
        @oid > 0
      end

      # Overridable. PDF types that must be indirect (Catalog, Pages, ...)
      # override to return true.
      def must_be_indirect?
        false
      end

      # Resolve a Reference; pass-through for everything else.
      def deref
        self
      end

      # The PDF /Type name (e.g. :Catalog). Subclasses override via
      # `define_type`. Falls back to value[:Type] for raw dicts.
      def pdf_type
        own = self.class.pdf_type
        return own if own
        return nil unless @value.is_a?(Hash)

        @value[:Type]
      end

      def ==(other)
        return false unless other.is_a?(Pdfrb::Model::Object)
        return object_id == other.object_id if indirect? && other.indirect?

        @value == other.value
      end

      class << self
        # Statically declare the /Type value for this class. Read via
        # `pdf_type`. Used by Document#wrap to dispatch.
        def define_type(type)
          @pdf_type = type
        end

        def pdf_type
          defined?(@pdf_type) ? @pdf_type : nil
        end
      end
    end
  end
end
