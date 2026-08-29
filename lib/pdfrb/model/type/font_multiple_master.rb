# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # MultipleMaster Type 1 font (s9.6.2.3). Type 1 font with
      # additional design axes between masters. Deprecated in PDF 2.0.
      class FontMultipleMaster < Font
        arlington_object "FontMultipleMaster"
        def subtype; self[:Subtype]&.to_sym; end
        def name; self[:Name]; end
        def first_char; self[:FirstChar]; end
        def last_char; self[:LastChar]; end
        def widths; self[:Widths]; end
        def font_descriptor; self[:FontDescriptor]; end
        def encoding; self[:Encoding]; end
        def blend_axis_types; self[:BlendAxisTypes]; end

        def mm_type1?
          subtype == :MMType1
        end

        def first_char_or_default
          first_char || 0
        end

        def last_char_or_default
          last_char || 255
        end

        def char_range
          [first_char_or_default, last_char_or_default]
        end
      end

      # CharProcMap (s9.6.4). Mapping from character names to the
      # content-stream procedures that draw them, used by Type 3 fonts.
      # The actual procedures live as streams under their names in a
      # Tiling pattern's Resources.
      class CharProcMap < Pdfrb::Model::Cos::Dictionary
        arlington_object "CharProcMap"
        include NameMap

        alias each_procedure each_entry
        alias procedure_for []

        def has_glyph?(char_name)
          !!procedure_for(char_name)
        end
      end
    end
  end
end
