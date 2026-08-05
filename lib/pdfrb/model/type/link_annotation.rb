# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class LinkAnnotation < Annotation
        def action; self[:A]; end
        def destination; self[:Dest]; end
        def highlight_mode; self[:H]; end
        def uri_action; self[:PA]; end
        def quad_points; self[:QuadPoints]; end
        def border; self[:Border]; end
        def bs; self[:BS]; end

        def has_action?
          !!action
        end

        def has_destination?
          !!destination
        end

        def uri_link?
          has_action? && action && action[:S]&.to_sym == :URI
        end

        def goto_link?
          has_action? && action && action[:S]&.to_sym == :GoTo
        end

        def launch_link?
          has_action? && action && action[:S]&.to_sym == :Launch
        end

        def highlight
          (highlight_mode || :Invert).to_sym
        end
      end
    end
  end
end
