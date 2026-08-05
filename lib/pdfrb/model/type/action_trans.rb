# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Transition action (s12.4.3). Specifies page transition for slide-show.
      class ActionTrans < Action
        register_subtype :Trans

        def transition; self[:Trans]; end

        def has_transition?
          !!transition
        end

        def transition_style
          return nil unless transition

          transition[:S]&.to_sym
        end

        def duration
          return nil unless transition

          transition[:D]
        end
      end
    end
  end
end
