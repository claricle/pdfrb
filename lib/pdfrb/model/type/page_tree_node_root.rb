# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
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
