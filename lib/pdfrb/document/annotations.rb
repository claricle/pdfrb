# frozen_string_literal: true

module Pdfrb
  class Document
    # Annotations facade (stub). Full implementation in TODO 131.
    class Annotations
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def add(page, subtype:, rect:, **opts)
        annot = document.add(
          {
            Type: :Annot,
            Subtype: subtype,
            Rect: rect,
            P: Pdfrb::Model::Reference.new(page.oid, page.gen),
            Contents: opts[:contents],
            F: opts[:flags] || 0
          }.compact,
          type: Pdfrb::Model::Type::Annotation
        )
        annots = (page.value[:Annots] ||= [])
        annots << Pdfrb::Model::Reference.new(annot.oid, annot.gen)
        annot
      end

      def each(page)
        return enum_for(:each, page) unless block_given?

        annots = page.value[:Annots]
        return self unless annots

        annots.each do |ref|
          a = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
          yield a if a
        end
        self
      end
    end
  end
end
