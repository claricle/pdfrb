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

        # Walk all leaf PageObjects under this node.
        def each_page(&block)
          return enum_for(:each_page) unless block_given?

          kids = self[:Kids] || []
          kids.each do |kid_ref|
            kid = kid_ref.is_a?(Pdfrb::Model::Reference) ?
                    document&.object(kid_ref) : kid_ref
            next unless kid

            case kid[:Type]
            when :Pages then kid.each_page(&block)
            when :Page then yield kid
            end
          end
        end

        def page_count
          self[:Count] || 0
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
