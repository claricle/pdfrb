# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ActionURI < Cos::Dictionary
        register_type action_type: :URI

        def uri
          self[:URI]
        end

        def track_mouse?
          self[:IsMap] == true
        end
      end
    end
  end
end
