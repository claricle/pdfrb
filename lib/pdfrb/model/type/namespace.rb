# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Namespace < Cos::Dictionary
        register_type :Namespace

        def namespace_name
          self[:NS]
        end

        def role_map_ns
          self[:RoleMapNS]
        end
      end
    end
  end
end
