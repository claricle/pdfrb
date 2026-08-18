# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Additional Actions for interactive form fields (s12.6.3.17,
      # Table 199). All four triggers carry JavaScript actions.
      class AddActionFormField < Pdfrb::Model::Cos::Dictionary
        arlington_object "AddActionFormField"

        # /K — keystroke: format before committing a changed value.
        def on_keystroke(document = nil)
          resolve_action(:K, document)
        end

        # /F — format: reformat after a new value is committed.
        def on_format(document = nil)
          resolve_action(:F, document)
        end

        # /V — validate (recalculate) after the field value changes.
        def on_validate(document = nil)
          resolve_action(:V, document)
        end

        # /C — recalculate when another field changes.
        def on_calculate(document = nil)
          resolve_action(:C, document)
        end

        private

        def resolve_action(key, document)
          ref = value[key]
          return nil unless ref && document

          ref.is_a?(Pdfrb::Model::Reference) ? document.object(ref) : ref
        end
      end
    end
  end
end
