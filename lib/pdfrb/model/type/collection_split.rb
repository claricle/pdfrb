# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection split (s7.11.5, PDF 1.7 Adobe extension level 3).
      # Where the portfolio view places the split between panels.
      class CollectionSplit < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionSplit"

        def direction; self[:Direction]; end
        def position; self[:Position]; end

        def vertical?
          direction == :V
        end

        def horizontal?
          direction == :H
        end
      end
    end
  end
end
