# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Optional Content Group (s8.11.2). Layer toggle for PDF layers.
      class OptionalContentGroup < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentGroup"
        register_type :OCG
      end

      # Optional Content Membership (s8.11.4.2). Boolean combination
      # of OCG visibility states.
      class OptionalContentMembership < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentMembership"
        register_type :OCMD
      end

      # Optional Content Properties (s8.11.1). Catalog /OCProperties.
      class OptionalContentProperties < Pdfrb::Model::Cos::Dictionary
        arlington_object "OptContentProperties"
      end
    end
  end
end
