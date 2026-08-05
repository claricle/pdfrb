# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Remote GoTo action (s12.6.4.3). Navigate to a destination in
      # another PDF file.
      class ActionGoToR < Action
        register_subtype :GoToR

        def file_spec; self[:F]; end
        def destination; self[:D]; end
        def new_window?; self[:NewWindow] == true; end
        def open_in_new_window?; new_window?; end

        def named_destination?
          destination.is_a?(String) || destination.is_a?(Symbol)
        end

        def page_index_destination?
          destination.is_a?(Array) && destination.first.is_a?(Integer)
        end
      end
    end
  end
end
