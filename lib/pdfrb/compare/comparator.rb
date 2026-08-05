# frozen_string_literal: true

module Pdfrb
  module Compare
    # Compares two Pdfrb::Documents at the structural level.
    # Walks pages, extracts text, inventories fonts/images,
    # inspects outlines and metadata. Produces a Report.
    class Comparator
      def compare(left, right)
        Report.new(
          page_count_delta: page_count_delta(left, right),
          per_page_text_diffs: per_page_text_diffs(left, right),
          font_diff: font_diff(left, right),
          image_count_delta: image_count_delta(left, right),
          outline_diff: outline_diff(left, right),
          metadata_diff: metadata_diff(left, right),
          structural_diffs: structural_diffs(left, right)
        )
      end

      private

      def page_count_delta(left, right)
        right.pages.count - left.pages.count
      end

      def per_page_text_diffs(left, right)
        left_text = extract_text_per_page(left)
        right_text = extract_text_per_page(right)

        max = [left_text.length, right_text.length].max
        (0...max).filter_map do |i|
          lt = left_text[i] || ""
          rt = right_text[i] || ""
          sim = text_similarity(lt, rt)
          next nil if sim >= 1.0 && lt == rt

          {
            page: i,
            similarity: sim,
            left_length: lt.length,
            right_length: rt.length,
            left_missing: chars_only_in(rt, lt),
            right_missing: chars_only_in(lt, rt),
          }
        end
      end

      def extract_text_per_page(doc)
        Pdfrb::Task::ExtractText.call(doc)
      rescue StandardError
        []
      end

      def text_similarity(a, b)
        return 1.0 if a == b
        return 0.0 if a.empty? || b.empty?

        max_len = [a.length, b.length].max
        lev = levenshtein(a, b)
        1.0 - (lev.to_f / max_len)
      end

      def levenshtein(a, b)
        m = a.length
        n = b.length
        return n if m.zero?
        return m if n.zero?

        d = Array.new(m + 1) { |i| [i] + Array.new(n, 0) }
        d[0] = (0..n).to_a

        (1..m).each do |i|
          (1..n).each do |j|
            cost = a[i - 1] == b[j - 1] ? 0 : 1
            d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
          end
        end
        d[m][n]
      end

      def chars_only_in(a, b)
        (a.chars.to_a - b.chars.to_a).uniq.first(20).join
      end

      def font_diff(left, right)
        left_fonts = inventory_fonts(left)
        right_fonts = inventory_fonts(right)

        {
          added: (right_fonts - left_fonts).sort,
          removed: (left_fonts - right_fonts).sort,
          common: (left_fonts & right_fonts).sort,
        }
      end

      def inventory_fonts(doc)
        fonts = Set.new
        doc.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)
          next unless obj[:Type] == :Font

          name = obj[:BaseFont] || obj[:Name] || "Unknown"
          subtype = obj[:Subtype] || "Unknown"
          fonts << "#{subtype}:#{name}"
        end
        fonts.to_a
      rescue StandardError
        []
      end

      def image_count_delta(left, right)
        right_count = count_images(right)
        left_count = count_images(left)
        right_count - left_count
      end

      def count_images(doc)
        count = 0
        doc.each_indirect_object do |obj|
          next unless obj.is_a?(Pdfrb::Model::Cos::Stream)
          next unless obj[:Subtype] == :Image

          count += 1
        end
        count
      rescue StandardError
        0
      end

      def outline_diff(left, right)
        left_titles = outline_titles(left)
        right_titles = outline_titles(right)

        {
          added: (right_titles - left_titles),
          removed: (left_titles - right_titles),
          common: (left_titles & right_titles),
        }
      end

      def outline_titles(doc)
        titles = Set.new
        outlines_ref = doc.catalog&.value&.dig(:Outlines)
        return titles.to_a unless outlines_ref

        outlines = doc.object(outlines_ref)
        return titles.to_a unless outlines

        walk_outline(outlines, doc) { |title| titles << title }
        titles.to_a
      rescue StandardError
        []
      end

      def walk_outline(outlines, doc, &)
        current = outlines[:First]
        while current
          entry = doc.object(current)
          break unless entry

          title = entry[:Title]
          yield(title.to_s) if title

          if entry[:First]
            child = doc.object(entry[:First])
            walk_outline(child, doc, &) if child
          end

          current = entry[:Next]
        end
      end

      def metadata_diff(left, right)
        left_info = extract_info(left)
        right_info = extract_info(right)

        diff = {}
        (left_info.keys | right_info.keys).each do |key|
          lv = left_info[key]
          rv = right_info[key]
          next if lv == rv

          diff[key] = { left: lv, right: rv }
        end
        diff
      end

      def extract_info(doc)
        trailer = doc.trailer || {}
        info_ref = trailer[:Info]
        return {} unless info_ref

        info = doc.object(info_ref)
        return {} unless info

        result = {}
        info.value.each do |k, v|
          next if k == :Type

          result[k] = v.to_s
        end
        result
      rescue StandardError
        {}
      end

      def structural_diffs(left, right)
        diffs = []

        lc = left.catalog
        rc = right.catalog
        if lc && rc
          left_keys = lc.value.keys.to_set
          right_keys = rc.value.keys.to_set

          added = right_keys - left_keys
          removed = left_keys - right_keys
          unless added.empty? && removed.empty?
            diffs << {
              location: "catalog",
              keys_added: added.to_a.sort,
              keys_removed: removed.to_a.sort,
            }
          end
        end

        lt = left.trailer || {}
        rt = right.trailer || {}
        left_tkeys = lt.keys.to_set - [:Size, :Root, :Prev]
        right_tkeys = rt.keys.to_set - [:Size, :Root, :Prev]
        unless (left_tkeys - right_tkeys).empty? && (right_tkeys - left_tkeys).empty?
          diffs << {
            location: "trailer",
            keys_added: (right_tkeys - left_tkeys).to_a.sort,
            keys_removed: (left_tkeys - right_tkeys).to_a.sort,
          }
        end

        diffs
      end
    end
  end
end
