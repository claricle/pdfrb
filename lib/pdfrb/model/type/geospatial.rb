# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Geographic coordinate system dictionary (s11.5, /GCS):
      # identifies a datum via EPSG code or WKT.
      class GeographicCoordinateSystem < Pdfrb::Model::Cos::Dictionary
        arlington_object "GeographicCoordinateSystem"

        def type; self[:Type]; end
        def epsg; self[:EPSG]; end
        def wkt; self[:WKT]; end

        def epsg_defined?
          !epsg.nil?
        end
      end

      # Projected coordinate system dictionary (s11.5, /DCS):
      # projection plus its underlying geographic system.
      class ProjectedCoordinateSystem < Pdfrb::Model::Cos::Dictionary
        arlington_object "ProjectedCoordinateSystem"

        def type; self[:Type]; end
        def epsg; self[:EPSG]; end
        def wkt; self[:WKT]; end
      end

      # Point-data dictionary (s11.5, /PtData): named point arrays
      # mapping geographic to page coordinates.
      class PointData < Pdfrb::Model::Cos::Dictionary
        arlington_object "PointData"

        def type; self[:Type]; end
        def subtype; self[:Subtype]; end
        def names; self[:Names]; end
        def xpts; self[:XPTS]; end
      end

      # Projection dictionary (s11.5, 3D annotation /Projection):
      # how 3D content is projected to the page.
      class Projection < Pdfrb::Model::Cos::Dictionary
        arlington_object "Projection"

        def subtype; self[:Subtype]; end
        def color_space; self[:CS]; end
        def focal_length; self[:F]; end
        def near; self[:N]; end
        def field_of_view; self[:FOV]; end
        def projection_scale; self[:PS]; end
        def orthographic_scale; self[:OS]; end
        def clipping_bbox; self[:OB]; end
      end

      # Number format dictionary (s11.4.2): unit, precision, and
      # denominators for measurement display.
      class NumberFormat < Pdfrb::Model::Cos::Dictionary
        arlington_object "NumberFormat"

        def type; self[:Type]; end
        def unit; self[:U]; end
        def conversion_factor; self[:C]; end
        def fractional_digits; self[:F]; end
        def denominator; self[:D]; end
        def fd; self[:FD]; end
        def fraction_display_type; self[:RT]; end
        def rounding_type; self[:RD]; end
        def thousands_separator; self[:PS]; end
        def negative_style; self[:SS]; end
        def pre_text; self[:O]; end
      end
    end
  end
end
