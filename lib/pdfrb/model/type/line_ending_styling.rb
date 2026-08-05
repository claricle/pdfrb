# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # LineEndingStyling (s12.5.5). /LE array of line-ending styles
      # (None, OpenArrow, ClosedArrow, Butt, Diamond, Square, etc.).
      class LineEndingStyling < Cos::Dictionary
        register_type :LineEndingStyling

        def type; self[:Type]; end
        def line_endings; self[:LE]; end

        def line_start
          return nil unless line_endings

          arr = line_endings.is_a?(Pdfrb::Model::PdfArray) ? line_endings.to_a : line_endings
          arr.is_a?(Array) ? arr[0] : nil
        end

        def line_end
          return nil unless line_endings

          arr = line_endings.is_a?(Pdfrb::Model::PdfArray) ? line_endings.to_a : line_endings
          arr.is_a?(Array) ? arr[1] : nil
        end

        def symmetric?
          line_start == line_end
        end

        def has_arrows?
          [:OpenArrow, :ClosedArrow].include?(line_start&.to_sym) ||
            [:OpenArrow, :ClosedArrow].include?(line_end&.to_sym)
        end
      end
    end
  end
end
