# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Background (s13.6.4). Background fill for a 3D view.
      class ThreeDBackground < Pdfrb::Model::Cos::Dictionary
        arlington_object "3DBackground"
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end
        def color_space; self[:CS]; end
        def color; self[:C]; end
        def enable_alpha?; truthy?(self[:EA]); end

        def solid_color?
          subtype == :SC
        end

        def image_background?
          subtype == :I
        end

        def default_white?
          color == [1, 1, 1]
        end
      end
    end
  end
end
