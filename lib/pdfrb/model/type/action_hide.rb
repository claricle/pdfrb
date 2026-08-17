# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Hide action (s12.6.4.10). Show/hide annotations.
      class ActionHide < Action
        arlington_object "ActionHide"
        register_subtype :Hide

        def targets; self[:T]; end
        def hide?; self[:H] != false; end

        def each_target
          return enum_for(:each_target) unless block_given?
          return unless targets && document

          arr = targets.is_a?(Array) ? targets : [targets]
          arr.each do |ref|
            obj = ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
            yield obj if obj
          end
        end
      end
    end
  end
end
