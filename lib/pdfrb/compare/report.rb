# frozen_string_literal: true

module Pdfrb
  module Compare
    # Result of comparing two PDFs. Immutable value object.
    class Report
      attr_reader :page_count_delta, :per_page_text_diffs,
                  :font_diff, :image_count_delta,
                  :outline_diff, :metadata_diff, :structural_diffs

      def initialize(page_count_delta:, per_page_text_diffs:, font_diff:,
                     image_count_delta:, outline_diff:, metadata_diff:,
                     structural_diffs:)
        @page_count_delta = page_count_delta
        @per_page_text_diffs = per_page_text_diffs.freeze
        @font_diff = font_diff.freeze
        @image_count_delta = image_count_delta
        @outline_diff = outline_diff.freeze
        @metadata_diff = metadata_diff.freeze
        @structural_diffs = structural_diffs.freeze
        freeze
      end

      def equivalent?
        return false unless @page_count_delta.zero?
        return false unless @per_page_text_diffs.empty?
        return false unless @font_diff[:added].empty? && @font_diff[:removed].empty?
        return false unless @image_count_delta.zero?
        return false unless @structural_diffs.empty?

        true
      end

      def similarity
        total_checks = 0
        passing = 0

        total_checks += 1
        passing += 1 if @page_count_delta.zero?

        total_checks += @per_page_text_diffs.length + 1
        passing += @per_page_text_diffs.count { |d| d[:similarity] > 0.95 } + 1

        total_checks += 1
        passing += 1 if @font_diff[:added].empty? && @font_diff[:removed].empty?

        total_checks += 1
        passing += 1 if @image_count_delta.zero?

        total_checks + 1
        passing + (@structural_diffs.empty? ? 1 : 0)
        (passing.to_f / (total_checks + 1)).round(4)
      end

      def to_h
        {
          equivalent: equivalent?,
          similarity: similarity,
          page_count_delta: @page_count_delta,
          per_page_text_diffs: @per_page_text_diffs,
          font_diff: @font_diff,
          image_count_delta: @image_count_delta,
          outline_diff: @outline_diff,
          metadata_diff: @metadata_diff,
          structural_diffs: @structural_diffs,
        }
      end

      def summary
        status = equivalent? ? "EQUIVALENT" : "DIFFERENT"
        sim = (similarity * 100).round(1)
        "#{status} (#{sim}% similarity, page_delta=#{@page_count_delta}, " \
          "text_diffs=#{@per_page_text_diffs.length}, " \
          "font_changes=#{@font_diff[:added].length + @font_diff[:removed].length})"
      end
    end
  end
end
