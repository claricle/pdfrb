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
      end
    end
  end
end
