# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class InteriorColor < Cos::Dictionary
        register_type :InteriorColor
        def color; self[:IC]; end
      end
    end
  end
end
