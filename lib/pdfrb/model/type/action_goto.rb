# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoTo action (s12.6.4.2). Navigate to a destination.
      class ActionGoTo < Action
        register_subtype :GoTo

        def destination; self[:D]; end

        def page_index_destination?
          destination.is_a?(Array) && destination.first.is_a?(Integer)
        end

        def named_destination?
          destination.is_a?(Symbol) || destination.is_a?(String)
        end

        def target_page_number
          return nil unless page_index_destination?

          destination.first
        end

        def display_option
          return nil unless page_index_destination?

          destination[1..]
        end
      end
    end
  end
end
