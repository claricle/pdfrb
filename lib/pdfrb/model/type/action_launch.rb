# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class ActionLaunch < Cos::Dictionary
        register_type action_type: :Launch

        def file_spec
          self[:F]
        end

        def new_window?
          self[:NewWindow] == true
        end
      end
    end
  end
end
