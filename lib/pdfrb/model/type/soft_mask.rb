# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Soft-mask dictionary /SMask in an ExtGState (s11.6.5.2).
      # The transfer function TR and backdrop color BC apply while
      # compositing the mask group G.
      class SoftMaskAlpha < Pdfrb::Model::Cos::Dictionary
        arlington_object "SoftMaskAlpha"

        def type; self[:Type]; end
        def subtype; self[:S]; end
        def group; self[:G]; end
        def backdrop_color; self[:BC]; end
        def transfer_function; self[:TR]; end

        def alpha?; true; end
        def luminosity?; false; end
      end

      # Luminosity soft mask (s11.6.5.3): the group's luminosity
      # drives the mask.
      class SoftMaskLuminosity < Pdfrb::Model::Cos::Dictionary
        arlington_object "SoftMaskLuminosity"

        def type; self[:Type]; end
        def subtype; self[:S]; end
        def group; self[:G]; end
        def backdrop_color; self[:BC]; end
        def transfer_function; self[:TR]; end

        def alpha?; false; end
        def luminosity?; true; end
      end

      # Resources /ExtGState dictionary (s7.8.3): name ->
      # ExtGState dictionaries.
      class GraphicsStateParameterMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "GraphicsStateParameterMap"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def add(name, parameters)
          value[name.to_sym] = parameters
          name.to_sym
        end

        def names
          value.keys
        end
      end

      # Transparency group /Group dictionary (s11.2.4.5): isolation
      # and knockout flags, blending color space.
      class GroupAttributes < Pdfrb::Model::Cos::Dictionary
        arlington_object "GroupAttributes"

        def type; self[:Type]; end
        def subtype; self[:S]; end
        def color_space; self[:CS]; end
        def isolated?; self[:I] == true; end
        def knockout?; self[:K] == true; end

        def transparency_group?
          subtype == :Transparency
        end
      end
    end
  end
end
