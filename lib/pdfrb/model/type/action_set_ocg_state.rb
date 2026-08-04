# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ActionSetOCGState < Cos::Dictionary
        register_type action_type: :SetOCGState
        def state; self[:State]; end
        def preserve_rb?; self[:PreserveRB] == true; end
      end
    end
  end
end
