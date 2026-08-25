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

        # The PageTreeNode TSV marks /Parent required; the root TSV
        # omits the key entirely (the root must NOT have a parent),
        # so neutralise the inherited requirement here.
        define_field :Parent, type: Pdfrb::Model::Cos::Dictionary, required: false

        def root?
          true
        end
      end
    end
  end
end
