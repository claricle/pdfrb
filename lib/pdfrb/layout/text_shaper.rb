# frozen_string_literal: true

module Pdfrb
  module Layout
    # Text shaping interface. Pure-Ruby shapers don't exist for the
    # complexity of OpenType GSUB/GPOS — this module defines the
    # contract that a real shaper (HarfBuzz, fribidi, etc.) must
    # satisfy. Callers can plug in a shaper implementation via
    # Pdfrb::Layout::TextShaper.implementation = MyShaper.
    #
    # The default implementation is grapheme-cluster-aware: it keeps
    # each user-perceived character (a base + combining marks, a
    # Hangul syllable, an emoji-ZWJ sequence, etc.) together as one
    # cluster so the TextLayouter measures and breaks at cluster
    # boundaries, never inside one.
    module TextShaper
      @implementation = nil

      ShapedRun = Struct.new(:codepoints, :clusters, :advances,
                             :cluster_starts, keyword_init: true)

      class << self
        attr_accessor :implementation

        # Shape +text+ for +font+ at +size+. Returns a ShapedRun.
        #
        # When an +implementation+ is registered, delegates to it.
        # Otherwise runs the default grapheme-cluster shaper.
        def shape(text, font: nil, size: 12, direction: :ltr)
          if implementation
            return implementation.shape(text, font: font, size: size,
                                              direction: direction)
          end

          default_shape(text, size, direction)
        end

        private

        # Default shaper: one cluster per grapheme. Each cluster's
        # advance is its base-codepoint width (combining marks add
        # zero). Falls back to size/2 when font metrics aren't
        # available.
        def default_shape(text, size, _direction)
          clusters = text.to_s.grapheme_clusters.to_a
          codepoints = []
          cluster_indices = []
          advances = []
          cluster_starts = []

          clusters.each_with_index do |cluster, cluster_idx|
            cluster_starts << codepoints.length
            cps = cluster.codepoints.to_a
            cps.each do |cp|
              codepoints << cp
              cluster_indices << cluster_idx
              advances << advance_for(cp, size, cps)
            end
          end

          ShapedRun.new(
            codepoints: codepoints,
            clusters: cluster_indices,
            advances: advances,
            cluster_starts: cluster_starts
          )
        end

        # Per-codepoint advance. Combining marks (Unicode general
        # category M*) contribute 0; everything else gets size/2
        # as a heuristic unless real metrics are available.
        def advance_for(codepoint, size, _cluster_cps)
          return 0.0 if combining_mark?(codepoint)
          return size * 0.6 if wide?(codepoint)

          # Heuristic average advance for ASCII range.
          size / 2.0
        end

        # Combining marks: Unicode general categories Mn, Mc, Me.
        # Subset of common ranges; the full list is in
        # UnicodeData.txt.
        def combining_mark?(codepoint)
          ranges = [
            0x0300..0x036F,   # Combining Diacritical Marks
            0x0483..0x0489,
            0x0591..0x05BD,
            0x05BF..0x05BF,
            0x05C1..0x05C2, 0x05C4..0x05C5, 0x05C7..0x05C7,
            0x0610..0x061A,
            0x064B..0x065F,
            0x0670..0x0670,
            0x06D6..0x06DC,
            0x06DF..0x06E4,
            0x06E7..0x06E8,
            0x06EA..0x06ED,
            0x0711..0x0711,
            0x0730..0x074A,
            0x0900..0x0903,
            0x093A..0x094F,
            0x0951..0x0957,
            0x20D0..0x20FF,   # Combining marks for symbols
            0xFE00..0xFE0F    # Variation selectors
          ]
          ranges.any? { |r| r.cover?(codepoint) }
        end

        # Wide characters: CJK + emoji. These typically take 1em
        # advance (double-width of a Latin letter).
        def wide?(codepoint)
          ranges = [
            0x1100..0x115F,   # Hangul Jamo
            0x2E80..0x303E,   # CJK Radicals
            0x3040..0x33BF,   # Hiragana, Katakana, CJK
            0x3400..0x4DBF,   # CJK Extension A
            0x4E00..0x9FFF,   # CJK Unified Ideographs
            0xA000..0xA4CF,   # Yi
            0xAC00..0xD7A3,   # Hangul Syllables
            0xF900..0xFAFF,   # CJK Compatibility Ideographs
            0xFE30..0xFE4F,   # CJK Compatibility Forms
            0x1F000..0x1FAFF, # Emoji + extensions
            0x20000..0x2FFFF, # CJK Extension B+
          ]
          ranges.any? { |r| r.cover?(codepoint) }
        end
      end
    end
  end
end
