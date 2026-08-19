# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection item (s7.11.5). Per-embedded-file values for the
      # schema fields.
      class CollectionItem < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionItem"
        def value_for(field_name)
          self[field_name.to_sym] || self[field_name.to_s]
        end

        def keys
          value.keys
        end
      end
    end
  end
end
