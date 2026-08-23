# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Pattern dictionary base (s8.7.2). Patterns tile or shade to fill
      # graphics. Two pattern types: tiling (Type 1) and shading (Type 2).
      class Pattern < Pdfrb::Model::Cos::Dictionary
        def pattern_type; self[:PatternType]; end

        def tiling?; pattern_type == 1; end
        def shading?; pattern_type == 2; end
      end

      # Resources /Pattern dictionary (s7.8.5). Maps resource names
      # to patterns.
      class PatternMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "PatternMap"

        def [](name)
          value[name.to_sym] || value[name.to_s]
        end

        def add(name, pattern)
          value[name.to_sym] = pattern
          name.to_sym
        end

        def each_pattern(&)
          return enum_for(:each_pattern) unless block_given?

          value.each(&)
        end

        def names
          value.keys
        end
      end
    end
  end
end
