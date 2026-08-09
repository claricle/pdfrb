# frozen_string_literal: true

module Pdfrb
  module Layout
    # Knuth-Liang hyphenation algorithm, pure Ruby. Uses a small
    # built-in pattern set covering common English patterns; callers
    # can supply their own pattern list for other languages.
    #
    # Patterns come from TeX's .pat files. Each pattern has letters
    # and digits where the digits encode the hyphenation weights
    # (0=never, 1-9=allowed). Example: ".abc1de" means "before 'd'
    # in 'abcde' you may hyphenate".
    #
    # The full English pattern set is ~62 KB. We ship a curated
    # subset; users who need full coverage can pass their own
    # +patterns:+ at construction.
    module Hyphenation
      # Curated subset covering common English word endings and
      # prefixes. Not exhaustive but useful for plain prose. Numbers
      # are weights; a weight of 1 means "may hyphenate here".
      #
      # Loaded from data/pdfrb/layout/hyphenation_en.txt so the
      # patterns stay reviewable; falls back to an empty list if the
      # data file is missing.
      PATTERNS_EN = begin
        path = File.expand_path("../../../data/pdfrb/layout/hyphenation_en.txt", __dir__)
        File.exist?(path) ? File.readlines(path, chomp: true).reject(&:empty?) : []
      rescue StandardError
        []
      end.freeze

      module_function

      # @param word [String] the word to hyphenate.
      # @param patterns [Array<String>] Knuth-Liang patterns.
      # @return [Array<Integer>] positions in +word+ where a hyphen
      #   may be inserted (between characters).
      def hyphenate_positions(word, patterns: PATTERNS_EN)
        return [] if word.length < 4

        lowered = word.downcase.gsub(/[^a-z]/, "")
        return [] if lowered.length < 4

        weights = word_weights(lowered, patterns)
        positions = []
        # Odd weights between two characters mean a hyphen is allowed.
        # Skip first and last character per Knuth-Liang rule.
        (1...lowered.length).each do |i|
          next if i < 2 || i > lowered.length - 2

          positions << i if weights[i].odd?
        end
        positions
      end

      # Split +word+ into segments at valid hyphenation points.
      # Includes the hyphen char (U+2010) on non-final segments when
      # +with_hyphen:+ is true.
      def split(word, patterns: PATTERNS_EN, with_hyphen: true)
        positions = hyphenate_positions(word, patterns: patterns)
        return [word] if positions.empty?

        segments = []
        prev = 0
        positions.each do |pos|
          segment = word[prev...pos] || ""
          segment += "‐" if with_hyphen
          segments << segment
          prev = pos
        end
        segments << (word[prev..] || "")
        segments
      end

      # Compute the per-character weights by overlaying every
      # matching pattern. The weight at position i in the word is the
      # max across all matching patterns at that inter-character slot.
      def word_weights(word, patterns)
        padded = ".#{word}."
        weights = ::Array.new(word.length + 1, 0)
        patterns.each do |pattern|
          apply_pattern(weights, padded, pattern)
        end
        weights
      end

      # Decode a Knuth-Liang pattern into [letters, weights]. The
      # letters are the alphabetic chars; the weights array has
      # weights.length == letters.length + 1 (the slots between
      # letters, including before and after).
      def decode_pattern(pattern)
        letters = +""
        weights = [0]
        pattern.each_char do |ch|
          if /[0-9]/.match?(ch)
            weights[-1] = [weights[-1], ch.to_i].max
          else
            letters << ch
            weights << 0
          end
        end
        [letters, weights]
      end

      def apply_pattern(weights, padded, pattern)
        letters, pat_weights = decode_pattern(pattern)
        start = 0
        while (idx = padded.index(letters, start))
          pat_weights.each_with_index do |w, i|
            next if w.zero?

            target = idx + i
            weights[target] = [weights[target], w].max if weights[target]
          end
          start = idx + 1
        end
      end
    end
  end
end
