# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ActionGoTo < Cos::Dictionary
        register_type action_type: :GoTo

        def destination
          self[:D]
        end
      end
    end
  end
end
