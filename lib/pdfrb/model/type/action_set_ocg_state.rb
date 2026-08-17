# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Set OCG State action (s12.6.4.13). Toggle visibility of
      # optional-content groups.
      class ActionSetOCGState < Action
        arlington_object "ActionSetOCGState"
        register_subtype :SetOCGState

        def state; self[:State]; end
        def preserve_rb?; self[:PreserveRB] == true; end

        def each_state_transition
          return enum_for(:each_state_transition) unless block_given?
          return unless state

          arr = state.is_a?(Pdfrb::Model::PdfArray) ? state.to_a : state
          return unless arr.is_a?(Array)

          current_op = :ON
          arr.each do |entry|
            case entry
            when :ON, :OFF, :Toggle then current_op = entry
            else yield current_op, entry
            end
          end
        end
      end
    end
  end
end
