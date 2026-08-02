# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # `OS/2` table parser. Exposes typographic extents and Windows
      # metrics used to compute font ascent / descent / cap height
      # for layout.
      #
      # Spec: OpenType "OS/2" versions 1–5; offsets vary by version.
      # Only the fields relevant to layout are exposed.
      class OS2
        attr_reader :version, :s_typo_ascender, :s_typo_descender,
                    :s_typo_line_gap, :us_win_ascent, :us_win_descent,
                    :sx_height, :s_cap_height, :us_weight_class,
                    :fs_selection

        def initialize(data)
          @data = data
          return unless data && data.bytesize >= 78

          @version = u16(0)
          @s_typo_ascender = s16(68)
          @s_typo_descender = s16(70)
          @s_typo_line_gap = s16(72)
          @us_win_ascent = u16(74)
          @us_win_descent = u16(76)

          return unless @version >= 2 && data.bytesize >= 96

          @sx_height = s16(86)
          @s_cap_height = s16(88)
          @us_weight_class = u16(4)
          @fs_selection = u16(62)
        end

        def bold?; (@fs_selection || 0) & 0x20 != 0; end
        def italic?; (@fs_selection || 0) & 0x01 != 0; end

        private

        def u16(off); (@data.getbyte(off) * 256) + @data.getbyte(off + 1); end

        def s16(off)
          v = u16(off)
          v >= 0x8000 ? v - 0x10000 : v
        end
      end
    end
  end
end
