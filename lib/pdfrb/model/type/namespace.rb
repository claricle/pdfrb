# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Namespace dictionary (s14.7.6.1, PDF 2.0). Namespaces for
      # structure element types in tagged PDF documents.
      class Namespace < Cos::Dictionary
        register_type :Namespace

        def type; self[:Type]; end
        def namespace_name; self[:NS]; end
        def role_map_ns; self[:RoleMapNS]; end

        def has_role_map?
          !!role_map_ns
        end

        def mapped_role(custom_name)
          return nil unless role_map_ns.is_a?(Hash)

          role_map_ns[custom_name.to_sym] || role_map_ns[custom_name.to_s]
        end
      end
    end
  end
end
