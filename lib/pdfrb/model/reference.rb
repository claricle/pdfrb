# frozen_string_literal: true

module Pdfrb
  module Model
    # A pointer to an indirect object (s7.3.10). Value-equal by (oid, gen)
    # so it can be a Hash key. Stored inside dictionaries/arrays wherever
    # an indirect reference appears in source.
    class Reference
      include Comparable

      attr_reader :oid, :gen

      def initialize(oid, gen = 0)
        @oid = oid.to_i
        @gen = gen.to_i
        freeze
      end

      def <=>(other)
        return nil unless other.is_a?(Reference)

        [oid, gen] <=> [other.oid, other.gen]
      end

      def hash
        [oid, gen].hash
      end

      def eql?(other)
        other.is_a?(Reference) && oid == other.oid && gen == other.gen
      end

      alias == eql?

      def to_s
        "#{oid} #{gen} R"
      end

      def inspect
        "#<Pdfrb::Model::Reference oid=#{oid} gen=#{gen}>"
      end

      # Resolve via the document's object reader. Returns an Object.
      def deref(document)
        document.object(self)
      end
    end
  end
end
