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
        # No eager /Resources: an empty page-level dict would override
        # the inheritable root resources (s7.7.3.2). The canvas seeds
        # one lazily when it attaches XObjects.
        page_hash = {
          Type: :Page,
          Parent: Pdfrb::Model::Reference.new(root.oid, root.gen),
          MediaBox: media_box,
          Contents: Pdfrb::Model::Reference.new(contents.oid, 0)
        }
        page_hash[:BleedBox] = bleed_box if bleed_box
        page_hash[:TrimBox] = trim_box if trim_box
        page_hash[:ArtBox] = art_box if art_box
        page_hash[:CropBox] = crop_box if crop_box
        page = document.add(page_hash, type: Pdfrb::Model::Type::Page)
        page.value[:Rotate] = rotate if rotate.nonzero?
        kids = (root.value[:Kids] ||= [])
        kids << Pdfrb::Model::Reference.new(page.oid, page.gen)
        root.value[:Count] = (root.value[:Count] || 0) + 1
        page
      end
      alias << add

      def each(&)
        return enum_for(:each) unless block_given?

        walk(pages_root, &)
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

      # Delete the page at +index+ (0-based).
      def delete_at(index)
        page = self[index]
        return nil unless page

        delete(page)
      end

      # Set /Rotate on every page. +angle+ must be 0, 90, 180, or 270.
      def rotate(angle)
        each { |page| page.value[:Rotate] = angle }
        self
      end

      # Move a page from one position to another.
      # @param from [Integer] source index (0-based).
      # @param to [Integer] destination index (0-based).
      def move(from, to)
        return self if from == to

        root = pages_root
        kids = root.value[:Kids]
        return self unless kids.is_a?(::Array)

        page = self[from]
        return self unless page

        ref = ref_to(page)
        kids.delete(ref)
        # Clamp to valid range after deletion.
        insert_at = to > from ? to - 1 : to
        kids.insert(insert_at, ref)
        self
      end

      # Iterate pages with index.
      def each_with_index(&)
        return enum_for(:each_with_index) unless block_given?

        i = 0
        each do |page|
          yield page, i
          i += 1
        end
      end

      # The page-tree root (Catalog /Pages), seeding an empty tree if
      # needed. Resources placed here are inherited by every page
      # (s7.7.3.2).
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

      private

      def walk(node, &block)
        kids = node.is_a?(Pdfrb::Model::Cos::Dictionary) ? node.value[:Kids] : node[:Kids]
        return unless kids

        kids = document.object(kids).value if kids.is_a?(Pdfrb::Model::Reference)
        kids = kids.value if kids.is_a?(Pdfrb::Model::Cos::Dictionary) && !kids.is_a?(::Hash)

        Array(kids).each do |kid_ref|
          kid = kid_ref.is_a?(Pdfrb::Model::Reference) ?
                  document.object(kid_ref) : kid_ref
          next unless kid

          type = kid.is_a?(Pdfrb::Model::Cos::Dictionary) ? kid.value[:Type] : nil
          case type
          when :Pages then walk(kid, &block)
          when :Page then yield kid
          else
            # Unknown type — best effort, treat as a Page.
            yield kid if kid.is_a?(Pdfrb::Model::Cos::Dictionary)
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
