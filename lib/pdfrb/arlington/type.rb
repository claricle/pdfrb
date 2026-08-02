# frozen_string_literal: true

module Pdfrb
  module Arlington
    # The 17 pre-defined Arlington types. Each is a Symbol so it can
    # be used uniformly in TSV-derived metadata. Per INTERNAL_GRAMMAR.md
    # and README.md of the upstream model.
    module Type
      ALL = %i[
        array
        bitmask
        boolean
        date
        dictionary
        integer
        matrix
        name
        name-tree
        null
        number
        number-tree
        rectangle
        stream
        string
        string-ascii
        string-byte
        string-text
      ].freeze

      STRING_VARIANTS = %i[string string-ascii string-byte string-text].freeze
      NUMERIC_VARIANTS = %i[integer number bitmask].freeze
      TREE_VARIANTS = %i[name-tree number-tree].freeze

      module_function

      def valid?(sym)
        ALL.include?(sym)
      end
    end
  end
end
