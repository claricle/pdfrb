# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Page-resources dict (s7.8). Named lookups for fonts, xobjects,
      # colors, patterns, shadings, extgstate, properties.
      class Resources < Pdfrb::Model::Cos::Dictionary
        arlington_object "Resource"

        def font(name)
          lookup_named(:Font, name)
        end

        def xobject(name)
          lookup_named(:XObject, name)
        end

        def ext_gstate(name)
          lookup_named(:ExtGState, name)
        end

        def color_space(name)
          lookup_named(:ColorSpace, name)
        end

        def pattern(name)
          lookup_named(:Pattern, name)
        end

        def shading(name)
          lookup_named(:Shading, name)
        end

        def properties(name)
          lookup_named(:Properties, name)
        end

        private

        def lookup_named(key, name)
          sub = self[key]
          return nil unless sub.is_a?(::Hash) || sub.is_a?(Pdfrb::Model::Cos::Dictionary)

          ref = sub.value ? sub.value[name] : sub[name]
          return ref unless ref.is_a?(Pdfrb::Model::Reference) && document

          document.object(ref)
        end
      end
    end
  end
end
