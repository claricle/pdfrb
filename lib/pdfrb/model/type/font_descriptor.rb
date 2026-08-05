# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font descriptor (s9.8). Carries metrics + embedded font file.
      class FontDescriptor < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontDescriptorType1"

        def font_name; self[:FontName]; end
        def family_name; self[:FontFamily]; end
        def font_stretch; self[:FontStretch]; end
        def font_weight; self[:FontWeight]; end
        def flags; self[:Flags]; end
        def font_bbox; self[:FontBBox]; end
        def italic_angle; self[:ItalicAngle]; end
        def ascent; self[:Ascent]; end
        def descent; self[:Descent]; end
        def cap_height; self[:CapHeight]; end
        def x_height; self[:XHeight]; end
        def stem_v; self[:StemV]; end
        def stem_h; self[:StemH]; end
        def avg_width; self[:AvgWidth]; end
        def max_width; self[:MaxWidth]; end
        def missing_width; self[:MissingWidth]; end
        def char_set; self[:CharSet]; end

        def font_file; self[:FontFile]; end
        def font_file2; self[:FontFile2]; end
        def font_file3; self[:FontFile3]; end

        def embedded?
          !!(font_file || font_file2 || font_file3)
        end

        def font_file_reference
          font_file2 || font_file3 || font_file
        end

        def resolved_font_file
          ref = font_file_reference
          return nil unless ref && document

          document.object(ref)
        end

        def fixed_pitch?; flags&.anybits?(1); end
        def serif?; flags&.anybits?(2); end
        def symbolic?; flags&.anybits?(4); end
        def script?; flags&.anybits?(8); end
        def nonsymbolic?; flags&.anybits?(32); end
        def italic?; flags&.anybits?(64); end
        def all_cap?; flags&.anybits?(0x10000); end
        def small_cap?; flags&.anybits?(0x20000); end
        def force_bold?; flags&.anybits?(0x40000); end
      end
    end
  end
end
