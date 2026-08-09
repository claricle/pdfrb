# frozen_string_literal: true

module Pdfrb
  module Layout
    # Arabic kashida justification: stretches Arabic letters using
    # the tatweel (U+0640) character to fill a line, instead of (or
    # in addition to) inter-word spacing. The technique inserts
    # tatweel after selected letters (those with right-joining
    # behaviour) to grow the line width toward the target.
    module JustificationKashidas
      # Arabic letters with right-joining behaviour (kashida can be
      # inserted after these). Subset — covers the most common
      # letters. Full list per Unicode Arabic Joining_Type.
      RIGHT_JOINING = %w[
        ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي
        ـب ـت ـث ـج ـح ـخ ـس ـش ـص ـض ـط ـظ ـع ـغ ـف ـق ـك ـل ـم ـن ـه
      ].freeze

      TATWEEL = "ـ"

      module_function

      # Insert kashidas into +text+ to grow it to +target_width+
      # using +measure+ (a callable that returns the width of a
      # string). Returns the modified string. If the natural width
      # already meets target_width, returns text unchanged.
      def justify(text, target_width:, measure:)
        return text if text.to_s.empty?

        natural = measure.call(text)
        return text if natural >= target_width

        candidates = kashida_insertion_points(text)
        return text if candidates.empty?

        # Greedy: add one tatweel per candidate until target reached.
        result = text.to_s.dup
        added = 0
        loop do
          break if natural >= target_width
          break if added >= candidates.length * 3 # cap to avoid runaway

          pos = candidates[added % candidates.length]
          result = insert_at(result, pos + added, TATWEEL)
          added += 1
          natural = measure.call(result)
        end
        result
      end

      # Indices in +text+ where a tatweel may be inserted (after a
      # right-joining letter that's not already followed by a space).
      def kashida_insertion_points(text)
        points = []
        prev = nil
        text.to_s.each_char.with_index do |ch, i|
          next_char = text.to_s[i + 1]
          if RIGHT_JOINING.include?(ch) && next_char &&
              RIGHT_JOINING.include?(next_char)
            points << (i + 1)
          end
          prev = ch
        end
        points
      end

      def insert_at(string, pos, char)
        string[0...pos] + char + string[pos..]
      end
    end
  end
end
