# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # 3D View (s13.6.4). A single camera/lighting/material configuration
      # for a 3D stream.
      class ThreeDView < Pdfrb::Model::Cos::Dictionary
        arlington_object "3DView"
        def type; self[:Type]; end
        def external_name; self[:XN]; end
        def internal_name; self[:IN]; end
        def measure_space; self[:MS]&.to_sym; end
        def camera_to_world; self[:C2W]; end
        def u3d_path; self[:U3DPath]; end
        def camera_offset; self[:CO]; end
        def projection; self[:P]; end
        def measures; self[:MA]; end

        def matrix_space?
          measure_space == :M
        end

        def u3d_space?
          measure_space == :U3D
        end

        def has_measures?
          !!measures && (!measures.is_a?(Array) || !measures.empty?)
        end

        def resolved_projection
          ref = projection
          return nil unless ref && document

          document.object(ref)
        end
      end

      # 3DViewAddEntries (s13.6.2.8): extra keys a 3D view adds to
      # the base view dictionary.
      class ThreeDViewAddEntries < Pdfrb::Model::Cos::Dictionary
        arlington_object "3DViewAddEntries"

        def external_name; self[:XN]; end
        def internal_name; self[:IN]; end
        def background; self[:MS]; end
        def matrix; self[:MA]; end
        def camera_to_world; self[:C2W]; end
        def u3d_path; self[:U3DPath]; end
        def lighting_scheme; self[:CO]; end
      end
    end
  end
end
