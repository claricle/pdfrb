# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ActionJavaScript < Cos::Dictionary
        register_type action_type: :JavaScript

        def script
          self[:JS]
        end
      end
    end
  end
end
