# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Rich Media Presentation (s13.6.1). Visual presentation settings
      # for a RichMedia annotation (style, window, transparency, etc.).
      class RichMediaPresentation < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaPresentation"
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

      # RichMedia instance /Params (s13.6.2.9): FlashVars, bindings,
      # and cue points.
      class RichMediaParams < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaParams"

        def flash_vars; self[:FlashVars]; end
        def binding; self[:Binding]; end
        def binding_material; self[:BindingMaterial]; end
        def cue_points; self[:CuePoints]; end
        def settings; self[:Settings]; end
      end

      # RichMedia height constraints (s13.6.9.5): /Default /Max /Min
      # in percentages of window height.
      class RichMediaHeight < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaHeight"

        def default; self[:Default]; end
        def max; self[:Max]; end
        def min; self[:Min]; end
      end

      # RichMedia width constraints (s13.6.9.5).
      class RichMediaWidth < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaWidth"

        def default; self[:Default]; end
        def max; self[:Max]; end
        def min; self[:Min]; end
      end

      # RichMedia window/content positioning (s13.6.9.5): alignment
      # and offsets.
      class RichMediaPosition < Pdfrb::Model::Cos::Dictionary
        arlington_object "RichMediaPosition"

        def h_align; self[:HAlign]; end
        def v_align; self[:VAlign]; end
        def h_offset; self[:HOffset]; end
        def v_offset; self[:VOffset]; end
      end
    end
  end
end
