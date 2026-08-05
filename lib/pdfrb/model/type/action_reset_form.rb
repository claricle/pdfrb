# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Reset-form action (s12.7.6.3). Resets form fields to defaults.
      class ActionResetForm < Action
        register_subtype :ResetForm

        def fields; self[:Fields]; end
        def include_exclude?
          !!self[:Flags] && (self[:Flags] & 1) != 0
        end

        def has_field_list?
          !!fields && (!fields.is_a?(Array) || !fields.empty?)
        end
      end
    end
  end
end
