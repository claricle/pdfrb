# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Additional Actions for screen annotations (s12.6.3.17, PDF 1.5).
      # Media events on the screen's region.
      class AddActionScreenAnnotation < Pdfrb::Model::Cos::Dictionary
        arlington_object "AddActionScreenAnnotation"

        # /E — cursor enters the screen region.
        def on_cursor_enter(document = nil)
          resolve_action(:E, document)
        end

        # /X — cursor exits the screen region.
        def on_cursor_exit(document = nil)
          resolve_action(:X, document)
        end

        # /D — mouse button pressed inside.
        def on_mouse_down(document = nil)
          resolve_action(:D, document)
        end

        # /U — mouse button released inside.
        def on_mouse_up(document = nil)
          resolve_action(:U, document)
        end

        # /PO — page containing the screen is opened.
        def on_page_open(document = nil)
          resolve_action(:PO, document)
        end

        # /PC — page containing the screen is closed.
        def on_page_close(document = nil)
          resolve_action(:PC, document)
        end

        # /PV — screen becomes visible.
        def on_visible(document = nil)
          resolve_action(:PV, document)
        end

        # /PI — screen becomes invisible.
        def on_invisible(document = nil)
          resolve_action(:PI, document)
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
