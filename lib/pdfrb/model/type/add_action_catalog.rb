# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Additional Actions for the Catalog (ISO 32000-2 §12.6.3.17,
      # PDF 1.4+). Referenced via /AA on the Catalog dict. Each entry
      # is an indirect ECMAScript action triggered by the named
      # document event.
      class AddActionCatalog < Pdfrb::Model::Cos::Dictionary
        arlington_object "AddActionCatalog"

        # /DC — document close.
        def document_close(document = nil)
          resolve_action(:DC, document)
        end

        # /WS — will save.
        def will_save(document = nil)
          resolve_action(:WS, document)
        end

        # /DS — did save.
        def did_save(document = nil)
          resolve_action(:DS, document)
        end

        # /WP — will print.
        def will_print(document = nil)
          resolve_action(:WP, document)
        end

        # /DP — did print.
        def did_print(document = nil)
          resolve_action(:DP, document)
        end

        private

        def resolve_action(key, document)
          ref = value[key]
          return nil unless ref && document

          document.resolve(ref)
        end
      end
    end
  end
end
