# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D Measure base (s13.6.4). Common base for the 3D measure
      # subtypes: 3DC, AD3, LD3, PD3, RD3.
      class ThreeDMeasure < Pdfrb::Model::Cos::Dictionary
        def type; self[:Type]; end
        def subtype; self[:Subtype]&.to_sym; end

        def perpendicular_distance?; subtype == :PD3; end
        def linear_distance?; subtype == :LD3; end
        def radial_distance?; subtype == :RD3; end
        def angle?; subtype == :AD3; end
        def comment?; subtype == :"3DC"; end
      end
    end
  end
end
