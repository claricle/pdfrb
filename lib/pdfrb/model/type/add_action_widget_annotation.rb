# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Additional Actions for widget annotations (s12.6.3.17, PDF 1.2).
      # Mouse, focus, and page events on the widget's region.
      class AddActionWidgetAnnotation < Pdfrb::Model::Cos::Dictionary
        arlington_object "AddActionWidgetAnnotation"

        # /E — cursor enters the widget's region.
        def on_cursor_enter(document = nil)
          resolve_action(:E, document)
        end

        # /X — cursor exits the widget's region.
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

        # /Fo — widget receives input focus.
        def on_focus(document = nil)
          resolve_action(:Fo, document)
        end

        # /Bl — widget loses input focus.
        def on_blur(document = nil)
          resolve_action(:Bl, document)
        end

        # /PO — page containing the widget is opened.
        def on_page_open(document = nil)
          resolve_action(:PO, document)
        end

        # /PC — page containing the widget is closed.
        def on_page_close(document = nil)
          resolve_action(:PC, document)
        end

        # /PV — widget becomes visible.
        def on_visible(document = nil)
          resolve_action(:PV, document)
        end

        # /PI — widget becomes invisible.
        def on_invisible(document = nil)
          resolve_action(:PI, document)
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
