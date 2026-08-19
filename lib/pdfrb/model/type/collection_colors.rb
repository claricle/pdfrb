# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Collection colors (s7.11.5, PDF 1.7 Adobe extension level 3).
      # UI color scheme for the portfolio view; each value is a 0..1 RGB
      # or Gray component array.
      class CollectionColors < Pdfrb::Model::Cos::Dictionary
        arlington_object "CollectionColors"

        def background; self[:Background]; end
        def card_background; self[:CardBackground]; end
        def card_border; self[:CardBorder]; end
        def primary_text; self[:PrimaryText]; end
        def secondary_text; self[:SecondaryText]; end

        def gray_background?
          components(background) == 1
        end

        def rgb_background?
          components(background) == 3
        end

        private

        def components(color)
          return 0 if color.nil?

          color.is_a?(Pdfrb::Model::PdfArray) ? color.to_a.size : 0
        end
      end
    end
  end
end
