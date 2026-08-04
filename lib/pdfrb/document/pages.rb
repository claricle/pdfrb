# frozen_string_literal: true

module Pdfrb
  class Document
    # Page-tree facade. Exposes +add+, +[]+, +each+, +count+,
    # +delete+ against the Catalog's /Pages tree.
    class Pages
      include Enumerable

      attr_reader :document

      def initialize(document)
        @document = document
      end

      # Add a new page at the end of the page tree.
      #
      # Options:
      #   media_box: [0, 0, 612, 792]   # default US Letter
      #   rotate: 0                     # degrees
      #
      # Returns the new +Model::Type::Page+.
      def add(media_box: nil, rotate: 0, width: nil, height: nil,
             bleed_box: nil, trim_box: nil, art_box: nil, crop_box: nil)
        media_box ||= (width && height ? [0, 0, width, height] : [0, 0, 612, 792])
        media_box ||= (width && height ? [0, 0, width, height] : [0, 0, 612, 792])
        root = pages_root
        contents = document.add({}, type: Pdfrb::Model::Cos::Stream)
        page = document.add(
          page_hash = {
            Type: :Page,
            Parent: Pdfrb::Model::Reference.new(root.oid, root.gen),
            MediaBox: media_box,
            Resources: {},
            Contents: Pdfrb::Model::Reference.new(contents.oid, 0)
          }
          page_hash[:BleedBox] = bleed_box if bleed_box
          page_hash[:TrimBox] = trim_box if trim_box
          page_hash[:ArtBox] = art_box if art_box
          page_hash[:CropBox] = crop_box if crop_box

          page = document.add(
            page_hash,
          type: Pdfrb::Model::Type::Page
        )
        page.value[:Rotate] = rotate if rotate.nonzero?
        kids = (root.value[:Kids] ||= [])
        kids << Pdfrb::Model::Reference.new(page.oid, page.gen)
        root.value[:Count] = (root.value[:Count] || 0) + 1
        page
      end
      alias << add

      def each(&block)
        return enum_for(:each) unless block_given?

        walk(pages_root, &block)
        self
      end

      def count
        raw = pages_root[:Count]
        resolved = raw.is_a?(Pdfrb::Model::Reference) ? document.object(raw)&.value : raw
        case resolved
        when Integer then resolved
        when Numeric then resolved.to_i
        else
          # Fallback: walk the page tree.
          count = 0
          each { count += 1 }
          count
        end
      end
      alias size count
      alias length count

      def empty?
        count.zero?
      end

      def [](index)
        each_with_index { |p, i| return p if i == index }
        nil
      end

      def delete(page)
        ref = ref_to(page)
        root = pages_root
        kids = root.value[:Kids]
        return unless kids&.delete(ref)

        root.value[:Count] = (root.value[:Count] || 1) - 1
        page
      end

      private

      def pages_root
        catalog = document.catalog
        raise Pdfrb::Error, "Document has no Catalog" unless catalog

        ref = catalog.value[:Pages]
        return document.object(ref) if ref

        # No /Pages yet — seed an empty tree.
        root = document.add({ Type: :Pages, Kids: [], Count: 0 },
                            type: Pdfrb::Model::Type::PageTreeNode)
        catalog.value[:Pages] = Pdfrb::Model::Reference.new(root.oid, root.gen)
        root
      end

      def walk(node, &block)
        kids = node.respond_to?(:value) ? node.value[:Kids] : node[:Kids]
        return unless kids

        # Kids may itself be an indirect reference, especially in
        # compressed-object PDFs (FOP output).
        kids = document.object(kids).value if kids.is_a?(Pdfrb::Model::Reference)
        kids = kids.value if kids.respond_to?(:value) && !kids.is_a?(::Hash)

        Array(kids).each do |kid_ref|
          kid = kid_ref.is_a?(Pdfrb::Model::Reference) ?
                  document.object(kid_ref) : kid_ref
          next unless kid

          type = kid.respond_to?(:value) ? kid.value[:Type] : nil
          case type
          when :Pages then walk(kid, &block)
          when :Page then yield kid
          else
            # Unknown type — best effort, treat as a Page.
            yield kid if kid.respond_to?(:value)
          end
        end
      end

      def ref_to(page)
        return page if page.is_a?(Pdfrb::Model::Reference)

        Pdfrb::Model::Reference.new(page.oid, page.gen)
      end
    end
  end
end
