# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Additional Actions on a page object (ISO 32000-2 §12.6.3.16,
      # PDF 1.2+). /O fires on page open, /C on page close.
      class AddActionPageObject < Pdfrb::Model::Cos::Dictionary
        arlington_object "AddActionPageObject"

        # /O — action(s) on page open.
        def on_open(document = nil)
          resolve_action(:O, document)
        end

        # /C — action(s) on page close.
        def on_close(document = nil)
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
