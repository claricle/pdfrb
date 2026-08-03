# frozen_string_literal: true

module Pdfrb
  class Document
    # Page Labels facade. Generates the /PageLabels number tree on the
    # Catalog for custom page numbering (roman numerals, prefixed
    # arabic, etc.).
    #
    # Usage:
    #   doc.page_labels.set do
    #     style :roman, count: 5      # i, ii, iii, iv, v
    #     style :decimal, prefix: "A-" # A-1, A-2, ...
    #   end
    class PageLabels
      STYLES = {
        decimal: :D,
        roman_lower: :r,
        roman_upper: :R,
        alpha_lower: :a,
        alpha_upper: :A,
      }.freeze

      LabelRule = Struct.new(:style, :prefix, :start, :page_count, keyword_init: true)

      attr_reader :document, :rules

      def initialize(document)
        @document = document
        @rules = []
        @current_index = 0
      end

      # Add a page labeling rule for the next batch of pages.
      # @param style [Symbol] :decimal, :roman_lower, :roman_upper,
      #   :alpha_lower, :alpha_upper.
      # @param prefix [String] prefix prepended to each label.
      # @param start [Integer] starting number (default 1).
      # @param count [Integer, nil] number of pages this rule covers
      #   (nil = until next rule or end).
      def style(style, prefix: nil, start: 1, count: nil)
        @rules << LabelRule.new(
          style: STYLES.fetch(style),
          prefix: prefix,
          start: start,
          page_count: count
        )
        @current_index += count if count
        self
      end

      # Build the /PageLabels number tree and set it on the Catalog.
      def commit!
        return if @rules.empty?

        nums = build_nums_array
        document.catalog.value[:PageLabels] = { Nums: nums }
      end

      private

      def build_nums_array
        nums = []
        index = 0
        @rules.each do |rule|
          nums << index
          nums << rule_dict(rule)
          index += rule.page_count if rule.page_count
        end
        nums
      end

      def rule_dict(rule)
        dict = { S: rule.style }
        dict[:P] = rule.prefix if rule.prefix
        dict[:St] = rule.start unless rule.start == 1
        dict
      end
    end
  end
end
