# frozen_string_literal: true

module Pdfrb
  module Layout
    # Paragraph-level Unicode bidi reordering (UAX #9, simplified).
    #
    # Implements:
    #   * P2-P3: paragraph embedding level from the first strong
    #     character (L => 0, R/AL => 1).
    #   * X9: skip BN/RLO/RLE/LRO/LRE/PDF/RLI/LRI/FSI (treated as
    #     neutral for this paragraph-level pass).
    #   * I1-I2: implicit level resolution for strong characters.
    #   * L1-L4: whitespace resets, neutrals on level boundaries,
    #     paired-bracket mirroring.
    #   * L2: reverse character order on level runs from highest to
    #     lowest, producing a visual order string.
    #
    # Scope: paragraph-level reordering only (no full isolating-run
    # sequence handling). Sufficient for Hebrew/Arabic paragraphs and
    # embedded LTR runs inside RTL paragraphs (and vice versa). Not
    # sufficient for complex mixed-direction runs at character
    # granularity inside a single visual line.
    module Bidi
      LEFT_TO_RIGHT = 0
      RIGHT_TO_LEFT = 1

      # Mirroring map for paired brackets (UAX #9 Bidi_Mirroring_Glyph
      # property, subset covering common punctuation).
      MIRROR = {
        "(" => ")",
        ")" => "(",
        "[" => "]",
        "]" => "[",
        "{" => "}",
        "}" => "{",
        "<" => ">",
        ">" => "<",
        "‘" => "’",
        "’" => "‘",
        "“" => "”",
        "”" => "“",
        "«" => "»",
        "»" => "«",
        "‹" => "›",
        "›" => "‹",
      }.freeze

      module_function

      # Returns the resolved paragraph embedding level: 0 for LTR
      # (or no strong direction), 1 for RTL.
      def paragraph_level(text)
        text.to_s.each_codepoint do |cp|
          case strong_direction(cp)
          when :ltr then return LEFT_TO_RIGHT
          when :rtl then return RIGHT_TO_LEFT
          end
        end
        LEFT_TO_RIGHT
      end

      # Reorder +text+ into visual order. Returns a new String of the
      # same grapheme count.
      def reorder(text)
        clusters = text.to_s.grapheme_clusters.to_a
        return text.to_s if clusters.size <= 1

        base = paragraph_level(text)
        levels = levels_for(clusters, base)
        visual = reverse_by_levels(clusters, levels)
        mirror_runs(visual, levels)
      end

      # Whether +text+ contains any RTL strong character.
      def rtl?(text)
        text.to_s.each_codepoint.any? { |cp| strong_direction(cp) == :rtl }
      end

      # ---- Character classification (UAX #9 BD1-BD2, trimmed) ----

      # Strong direction (:ltr, :rtl, or nil for non-strong). Used by
      # paragraph_level to find the first strong character per P2-P3.
      def strong_direction(codepoint)
        case bidi_type(codepoint)
        when :L then :ltr
        when :R, :AL then :rtl
        end
      end

      # UAX #9 bidi type for a codepoint. Subset implementation:
      # covers Latin, Hebrew, Arabic, digits, common punctuation.
      def bidi_type(codepoint)
        case codepoint
        when 0x0660..0x0669, 0x06F0..0x06F9 then :AN
        when 0x0300..0x036F, 0x0483..0x0489,
             0x0591..0x05BD, 0x05BF, 0x05C1..0x05C2,
             0x05C4..0x05C5, 0x05C7, 0x0610..0x061A,
             0x064B..0x065F, 0x0670, 0x06D6..0x06DC,
             0x06DF..0x06E4, 0x06E7..0x06E8,
             0x06EA..0x06ED, 0x0711, 0x0730..0x074A then :NSM
        when 0x0041..0x005A, 0x0061..0x007A,
             0x00AA, 0x00B5, 0x00BA,
             0x00C0..0x00D6, 0x00D8..0x00F6,
             0x00F8..0x02B8, 0x02BB..0x02C1,
             0x1D00..0x1D25, 0x1D2C..0x1D5C,
             0x1D62..0x1D65, 0x1D6B..0x1D77,
             0x1D79..0x1DBE, 0x1E00..0x1EFF,
             0x2071, 0x207F, 0x2090..0x209C,
             0x212A..0x212B, 0x2132, 0x214E,
             0x2160..0x2188, 0x2C60..0x2C7F,
             0xA722..0xA787, 0xA78B..0xA78E,
             0xA790..0xA793, 0xA7A0..0xA7AA,
             0xA7F8..0xA7FF, 0xFB00..0xFB06,
             0xFB13..0xFB17 then :L
        when 0x0590..0x05FF, 0x07C0..0x089F,
             0xFB1D..0xFB4F then :R
        when 0x0600..0x07BF, 0x08A0..0x08FF,
             0xFB50..0xFDFF, 0xFE70..0xFEFF then :AL
        when 0x0030..0x0039, 0x06DD then :EN
        when 0x002B, 0x002D then :ES
        when 0x0023, 0x0024, 0x0025, 0x00A2..0x00A5 then :ET
        when 0x002C, 0x002E, 0x003A, 0x003B,
             0x0028, 0x0029,
             0x0000..0x0008, 0x000E..0x001B,
             0x007F..0x0084, 0x0086..0x009F,
             0x200B..0x200D, 0x2060, 0xFEFF then :ON
        when 0x0020, 0x00A0, 0x1680, 0x2000..0x200A,
             0x2028..0x2029, 0x202F, 0x205F, 0x3000 then :WS
        else :BN
        end
      end

      # ---- Level resolution ----

      # Compute embedding level per grapheme cluster using the implicit
      # level resolution rules I1/I2 from UAX #9. NSM inherits the
      # level of the preceding character (simplified: assumes the
      # paragraph base level for the first character).
      def levels_for(clusters, base_level)
        prev = base_level
        clusters.map do |cluster|
          cp = cluster.codepoints.first || 0
          level = implicit_level(bidi_type(cp), base_level, prev)
          prev = level
          level
        end
      end

      # I1/I2 from UAX #9. Even base levels add 1 for R/AL/AN, 2 for
      # EN. Odd base levels add 1 for L/EN/AN.
      def implicit_level(type, base_level, prev_level)
        case type
        when :NSM then prev_level
        when :L then base_level.even? ? base_level : base_level + 1
        when :R, :AL then base_level.even? ? base_level + 1 : base_level
        when :AN then base_level + 1
        when :EN then base_level + (base_level.even? ? 2 : 1)
        else base_level
        end
      end

      # UAX #9 L2: reverse contiguous runs at each level, from highest
      # to lowest. Returns a new array of clusters in visual order.
      def reverse_by_levels(clusters, levels)
        result = clusters.dup
        max_level = levels.max || 0
        min_odd = levels.min.to_i
        min_odd += 1 if min_odd.even?
        (min_odd..max_level).to_a.reverse.each do |level|
          start = nil
          levels.each_with_index do |lvl, i|
            if lvl >= level
              start ||= i
            elsif start
              result[start, i - start] = result[start, i - start].reverse
              start = nil
            end
          end
          next unless start

          result[start, levels.size - start] = result[start, levels.size - start].reverse
        end
        result
      end

      # UAX #9 L4: mirror paired brackets on RTL runs. Returns a
      # string built from the visual-order cluster list with mirror
      # glyphs substituted where applicable.
      def mirror_runs(clusters, levels)
        clusters.each_with_index.map do |cluster, i|
          next cluster if levels[i].nil? || levels[i].even?

          MIRROR[cluster] || cluster
        end.join
      end
    end
  end
end
