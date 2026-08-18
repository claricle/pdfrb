# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # GoToE action (s12.6.4.4, PDF 1.6). Navigate to a destination in
      # an embedded PDF file.
      class ActionGoToE < Action
        arlington_object "ActionGoToE"
        register_subtype :GoToE

        def target_file; self[:F]; end
        def destination; self[:D]; end
        def new_window; self[:NewWindow]; end
        def target; self[:T]; end

        def new_window?
          new_window == true
        end

        def targets_embedded_file?
          !target_file.nil?
        end

        def named_destination?
          destination.is_a?(Symbol) || destination.is_a?(String)
        end
      end
    end
  end
end
