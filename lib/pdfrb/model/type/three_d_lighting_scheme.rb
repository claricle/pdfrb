# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Lighting Scheme (s13.6.4, Table 320-321). Lighting preset.
      class ThreeDLightingScheme < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end

        def artwork?; subtype == :Artwork; end
        def none?; subtype == :None; end
        def white?; subtype == :White; end
        def day?; subtype == :Day; end
        def night?; subtype == :Night; end
        def hard?; subtype == :Hard; end
        def primary?; subtype == :Primary; end
        def blue?; subtype == :Blue; end
        def red?; subtype == :Red; end
        def cube?; subtype == :Cube; end
        def cad?; subtype == :CAD; end
        def headlamp?; subtype == :Headlamp; end
      end
    end
  end
end
