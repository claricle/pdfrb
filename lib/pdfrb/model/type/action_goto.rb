# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoTo action (s12.6.4.2). Navigate to a destination.
      class ActionGoTo < Action
        arlington_object "ActionGoTo"
        register_subtype :GoTo

        def destination; self[:D]; end

        def page_index_destination?
          d = destination_array
          !d.nil? && d.first.is_a?(Integer)
        end

        def named_destination?
          destination.is_a?(Symbol) || destination.is_a?(String)
        end

        def target_page_number
          return nil unless page_index_destination?

          destination_array.first
        end

        def display_option
          return nil unless page_index_destination?

          destination_array[1..]
        end

        private

        def destination_array
          d = destination
          return d.to_a if d.is_a?(Pdfrb::Model::PdfArray)
          return d if d.is_a?(::Array)

          nil
        end
      end
    end
  end
end
