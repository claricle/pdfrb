# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection schema (s7.11.5). Defines the columns/fields shown
      # in the portfolio view.
      class CollectionSchema < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionSchema"
        def fields
          value.keys
        end

        def field_count
          value.size
        end

        def each_field(&)
          return enum_for(:each_field) unless block_given?

          value.each(&)
        end
      end
    end
  end
end
