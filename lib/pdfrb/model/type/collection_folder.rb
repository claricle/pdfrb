# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection folder (s7.11.5, PDF 1.7 Adobe extension level 3).
      # A folder node in the portfolio's folder hierarchy.
      class CollectionFolder < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionFolder"

        def id; self[:ID]; end
        def name; self[:Name]; end
        def parent; self[:Parent]; end
        def child; self[:Child]; end
        def next_folder; self[:Next]; end
        def collection_item; self[:CI]; end
        def description; self[:Desc]; end
        def creation_date; self[:CreationDate]; end
        def modified_date; self[:ModDate]; end
        def thumbnail; self[:Thumb]; end
        def free; self[:Free]; end

        def root_folder?
          parent.nil?
        end

        def has_children?
          !child.nil?
        end
      end
    end
  end
end
