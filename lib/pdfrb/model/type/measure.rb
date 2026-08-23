# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Measure dictionary (s11.4). Used by line/poly annotations and
      # XObjects to map PDF units to real-world units.
      class Measure < Cos::Dictionary
        arlington_object "MeasureRL"
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

      # Geospatial Measure dictionary (s11.4, /Subtype /GEO with
      # GCS/DCS). Maps geographic coordinates onto page geometry.
      class GeospatialMeasure < Pdfrb::Model::Cos::Dictionary
        arlington_object "MeasureGEO"

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def bounds; self[:Bounds]; end
        def geographic_coordinate_system; self[:GCS]; end
        def projected_coordinate_system; self[:DCS]; end
        def pdu; self[:PDU]; end
        def gpts; self[:GPTS]; end
        def lpts; self[:LPTS]; end
        def pcsm; self[:PCSM]; end

        def bound_count
          arr = bounds
          arr = arr.to_a if arr.is_a?(Pdfrb::Model::PdfArray)
          arr&.size
        end
      end
    end
  end
end
