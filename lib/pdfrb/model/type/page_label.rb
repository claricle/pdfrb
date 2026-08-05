# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # PageLabel (s12.4.2). Catalog /PageLabels /Nums entry. Defines
      # how page numbers are displayed in the viewer.
      class PageLabel < Cos::Dictionary
        register_type :PageLabel

        def type; self[:Type]; end
        def style; self[:S]; end
        def prefix; self[:P]; end
        def start; self[:St] || 1; end

        def decimal_style?; style&.to_sym == :D; end
        def uppercase_roman_style?; style&.to_sym == :R; end
        def lowercase_roman_style?; style&.to_sym == :r; end
        def uppercase_letters_style?; style&.to_sym == :A; end
        def lowercase_letters_style?; style&.to_sym == :a; end

        def label_for(page_index)
          return prefix.to_s unless style

          number = start + page_index
          case style.to_sym
          when :D then "#{prefix}#{number}"
          when :R then "#{prefix}#{to_roman(number).upcase}"
          when :r then "#{prefix}#{to_roman(number).downcase}"
          when :A then "#{prefix}#{to_letters(number).upcase}"
          when :a then "#{prefix}#{to_letters(number).downcase}"
          else prefix.to_s
          end
        end

        private

        def to_roman(n)
          return "0" if n <= 0

          mappings = [
            [1000, "M"], [900, "CM"], [500, "D"], [400, "CD"],
            [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
            [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]
          ]
          result = +""
          mappings.each do |value, symbol|
            while n >= value
              result << symbol
              n -= value
            end
          end
          result
        end

        def to_letters(n)
          result = +""
          n -= 1
          while n >= 0
            result = (65 + (n % 26)).chr + result
            n = (n / 26) - 1
          end
          result
        end
      end
    end
  end
end
