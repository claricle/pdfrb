# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Page-resources dict (s7.8). Named lookups for fonts, xobjects,
      # colors, patterns, shadings, extgstate, properties.
      class Resources < Pdfrb::Model::Cos::Dictionary
        arlington_object "Resource"

        def fonts; self[:Font]; end
        def xobjects; self[:XObject]; end
        def ext_gstates; self[:ExtGState]; end
        def color_spaces; self[:ColorSpace]; end
        def patterns; self[:Pattern]; end
        def shadings; self[:Shading]; end
        def properties_dict; self[:Properties]; end
        def proc_set; self[:ProcSet]; end

        def font_names
          dict_keys(fonts)
        end

        def xobject_names
          dict_keys(xobjects)
        end

        def ext_gstate_names
          dict_keys(ext_gstates)
        end

        def color_space_names
          dict_keys(color_spaces)
        end

        def pattern_names
          dict_keys(patterns)
        end

        def shading_names
          dict_keys(shadings)
        end

        def font(name); lookup_named(:Font, name); end
        def xobject(name); lookup_named(:XObject, name); end
        def ext_gstate(name); lookup_named(:ExtGState, name); end
        def color_space(name); lookup_named(:ColorSpace, name); end
        def pattern(name); lookup_named(:Pattern, name); end
        def shading(name); lookup_named(:Shading, name); end
        def properties(name); lookup_named(:Properties, name); end

        def has_procset?(name)
          return false unless proc_set

          arr = proc_set.is_a?(Pdfrb::Model::PdfArray) ? proc_set.to_a : proc_set
          arr.is_a?(Array) && arr.include?(name)
        end

        def empty?
          %i[Font XObject ExtGState ColorSpace Pattern Shading Properties].all? do |k|
            value[k].nil? || (value[k].respond_to?(:empty?) && value[k].empty?)
          end
        end

        private

        def dict_keys(dict)
          return [] unless dict

          obj = dict.is_a?(Pdfrb::Model::Reference) && document ? document.object(dict) : dict
          case obj
          when Hash then obj.keys
          when Pdfrb::Model::Cos::Dictionary then obj.value.keys
          else []
          end
        end

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
