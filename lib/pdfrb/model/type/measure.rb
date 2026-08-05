# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Measure dictionary (s11.4). Used by line/poly annotations and
      # XObjects to map PDF units to real-world units.
      class Measure < Cos::Dictionary
        register_type :Measure

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def scale_ratio; self[:R]; end
        def x_scale; self[:X]; end
        def y_scale; self[:Y]; end
        def cyxy; self[:CYX]; end
        def cyy; self[:CYY]; end
        def distance_format; self[:D]; end
        def area_format; self[:A]; end
        def angular_format; self[:T]; end
        def slope_format; self[:S]; end
        def origin; self[:O]; end
        def ctp; self[:CYX]; end

        def rectilinear?
          subtype&.to_sym == :RL
        end

        def geographic?
          subtype&.to_sym == :GEO
        end

        def has_area_format?
          !!area_format
        end
      end
    end
  end
end
