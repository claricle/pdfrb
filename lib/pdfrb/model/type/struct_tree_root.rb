# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure tree root (s14.7.2). Catalog /StructTreeRoot.
      # Holds /Type, /K, /ParentTree, /ParentTreeNextKey, /RoleMap,
      # /ClassMap.
      class StructTreeRoot < Pdfrb::Model::Cos::Dictionary
        arlington_object "StructTreeRoot"
        register_type :StructTreeRoot

        def type; self[:Type]; end
        def children; self[:K]; end
        def parent_tree; self[:ParentTree]; end
        def parent_tree_next_key; self[:ParentTreeNextKey]; end
        def role_map; self[:RoleMap]; end
        def class_map; self[:ClassMap]; end

        def each_child
          return enum_for(:each_child) unless block_given?
          return unless children && document

          arr = children.is_a?(Pdfrb::Model::Reference) ? document.object(children) : children
          return unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          arr.each do |kid_ref|
            obj = kid_ref.is_a?(Pdfrb::Model::Reference) ? document.object(kid_ref) : kid_ref
            yield obj if obj
          end
        end

        def mapped_role(custom_name)
          return nil unless role_map.is_a?(::Hash)

          role_map[custom_name.to_sym] || role_map[custom_name.to_s]
        end

        def has_role_map?
          !!role_map
        end

        def has_class_map?
          !!class_map
        end
      end
    end
  end
end
