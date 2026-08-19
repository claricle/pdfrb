# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection sort (s7.11.5). Defines default sort order.
      class CollectionSort < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionSort"
        def field_name; self[:S]; end
        def descending?; truthy?(self[:A]); end
      end
    end
  end
end
