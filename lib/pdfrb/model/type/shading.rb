# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Common keys and type predicates shared by dict-based and
      # stream-based shadings (s8.7.4.1).
      module ShadingCommon
        def shading_type; self[:ShadingType]; end
        def color_space; self[:ColorSpace]; end
        def background; self[:Background]; end
        def bbox; self[:BBox]; end
        def anti_alias?; self[:AntiAlias] == true; end
        def domain; self[:Domain]; end
        def function; self[:Function]; end

        def function_based?; shading_type == 1; end
        def axial?; shading_type == 2; end
        def radial?; shading_type == 3; end
        def free_form_gouraud?; shading_type == 4; end
        def lattice_gouraud?; shading_type == 5; end
        def coons_patch?; shading_type == 6; end
        def tensor_patch?; shading_type == 7; end
      end

      class Shading < Pdfrb::Model::Cos::Dictionary
        include ShadingCommon
      end

      # Type 1 — function-based shading (s8.7.4.2).
      class ShadingType1 < Shading
        arlington_object "ShadingType1"

        def matrix; self[:Matrix]; end
      end

      # Type 2 — axial shading (s8.7.4.3).
      class ShadingType2 < Shading
        arlington_object "ShadingType2"

        def coords; self[:Coords]; end
        def extend; self[:Extend]; end

        def x0; coords && coords[0]; end
        def x1; coords && coords[2]; end
        def y0; coords && coords[1]; end
        def y1; coords && coords[3]; end

        def extends_start?; extend && extend[0] == true; end
        def extends_end?; extend && extend[1] == true; end
      end

      # Type 3 — radial shading (s8.7.4.4).
      class ShadingType3 < Shading
        arlington_object "ShadingType3"

        def coords; self[:Coords]; end
        def extend; self[:Extend]; end

        # [x0 y0 r0 x1 y1 r1].
        def r0; coords && coords[2]; end
        def r1; coords && coords[5]; end
      end

      # Type 4 — free-form Gouraud-shaded triangle mesh
      # (s8.7.4.6.3). Stream carrying vertex data.
      class ShadingType4 < Pdfrb::Model::Cos::Stream
        include ShadingCommon

        arlington_object "ShadingType4"

        def bits_per_coordinate; self[:BitsPerCoordinate]; end
        def bits_per_component; self[:BitsPerComponent]; end
        def bits_per_flag; self[:BitsPerFlag]; end
        def decode; self[:Decode]; end
      end

      # Type 5 — lattice Gouraud-shaded triangle mesh
      # (s8.7.4.6.4).
      class ShadingType5 < Pdfrb::Model::Cos::Stream
        include ShadingCommon

        arlington_object "ShadingType5"

        def bits_per_coordinate; self[:BitsPerCoordinate]; end
        def bits_per_component; self[:BitsPerComponent]; end
        def vertices_per_row; self[:VerticesPerRow]; end
        def decode; self[:Decode]; end
      end

      # Type 6 — Coons patch mesh (s8.7.4.7.4).
      class ShadingType6 < Pdfrb::Model::Cos::Stream
        include ShadingCommon

        arlington_object "ShadingType6"

        def bits_per_coordinate; self[:BitsPerCoordinate]; end
        def bits_per_component; self[:BitsPerComponent]; end
        def bits_per_flag; self[:BitsPerFlag]; end
        def decode; self[:Decode]; end
      end

      # Type 7 — tensor-product patch mesh (s8.7.4.7.5).
      class ShadingType7 < Pdfrb::Model::Cos::Stream
        include ShadingCommon

        arlington_object "ShadingType7"

        def bits_per_coordinate; self[:BitsPerCoordinate]; end
        def bits_per_component; self[:BitsPerComponent]; end
        def bits_per_flag; self[:BitsPerFlag]; end
        def decode; self[:Decode]; end
      end

      # Resources /Shading dictionary (s7.8.4). Maps resource names
      # to shadings.
      class ShadingMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "ShadingMap"
        include NameMap

        alias each_shading each_entry
      end
    end
  end
end
