# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Intermediate page-tree node (s7.7.3.2). Holds /Kids (array of
      # PageTreeNode or Page) + /Count + inheritable /MediaBox,
      # /CropBox, /Resources, /Rotate. The root uses the same dict
      # shape and is conventionally distinguished via PageTreeNodeRoot
      # for type-dispatch purposes.
      class PageTreeNode < Pdfrb::Model::Cos::Dictionary
        arlington_object "PageTreeNode"
        register_type :Pages

        def kids; self[:Kids]; end
        def count; self[:Count] || 0; end
        def parent; self[:Parent]; end
        def media_box; self[:MediaBox]; end
        def crop_box; self[:CropBox]; end
        def resources; self[:Resources]; end
        def rotate; self[:Rotate]; end

        def root?
          parent.nil?
        end

        def leaf?
          false
        end

        def each_child
          return enum_for(:each_child) unless block_given?
          return unless kids && document

          arr = kids.is_a?(Pdfrb::Model::Reference) ? document.object(kids) : kids
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |kid_ref|
            obj = kid_ref.is_a?(Pdfrb::Model::Reference) ? document.object(kid_ref) : kid_ref
            yield obj if obj
          end
        end

        # Walk all leaf PageObjects under this node.
        def each_page(&block)
          return enum_for(:each_page) unless block_given?

          each_child do |kid|
            case kid[:Type]
            when :Pages then kid.each_page(&block)
            when :Page then yield kid
            end
          end
        end

        def pages
          each_page.to_a
        end

        def page_count
          self[:Count] || 0
        end

        def first_page
          each_page.first
        end

        def last_page
          each_page.to_a.last
        end

        def page_at(index)
          return nil if index < 0 || index >= page_count
          each_page.each_with_index do |page, i|
            return page if i == index
          end
        end
      end

      # The root of the page tree — same shape as PageTreeNode but
      # linked directly from the Catalog's /Pages. Tracked separately
      # so type-dispatch can distinguish root from interior nodes
      # (some validation rules apply only to the root).
      class PageTreeNodeRoot < PageTreeNode
        arlington_object "PageTreeNodeRoot"
      end
    end
  end
end
