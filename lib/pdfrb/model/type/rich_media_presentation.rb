# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Presentation (s13.6.1). Visual presentation settings
      # for a RichMedia annotation (style, window, transparency, etc.).
      class RichMediaPresentation < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def style; self[:Style]&.to_sym; end
        def window; self[:Window]; end
        def transparent?; truthy?(self[:Transparent]); end
        def navigation_pane?; truthy?(self[:NavigationPane]); end
        def toolbar?; truthy?(self[:Toolbar]); end
        def pass_context_click?; truthy?(self[:PassContextClick]); end

        def embedded_style?; style == :Embedded; end
        def windowed_style?; style == :Windowed; end

        def resolved_window
          ref = window
          return nil unless ref && document

          document.object(ref)
        end
      end
    end
  end
end
