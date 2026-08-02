# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Structure element (s14.7.4). One node in the structure tree.
      # Holds /S (structure type), /P (parent), /K (kids), /Pg,
      # /A, /C. Per PDF/UA Tech Note 001, /ActualText may appear
      # for /Figure elements.
      class StructElem < Pdfrb::Model::Cos::Dictionary
        arlington_object "StructElem"
      end
    end
  end
end
