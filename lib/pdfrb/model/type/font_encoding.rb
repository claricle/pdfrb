# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Font Encoding dict (s9.6.1). Base encoding + per-glyph differences
      # table for Type 1 fonts.
      class FontEncoding < Pdfrb::Model::Cos::Dictionary
        def base_encoding; self[:BaseEncoding]&.to_sym; end
        def differences; self[:Differences]; end

        def win_ansi?; base_encoding == :WinAnsiEncoding; end
        def mac_roman?; base_encoding == :MacRomanEncoding; end
        def mac_expert?; base_encoding == :MacExpertEncoding; end
        def standard?; base_encoding == :StandardEncoding; end

        def has_differences?
          !!differences && (!differences.is_a?(Array) || !differences.empty?)
        end

        def each_difference(&block)
          return enum_for(:each_difference) unless block

          return unless differences.is_a?(Array)

          current_code = nil
          differences.each do |entry|
            if entry.is_a?(Integer)
              current_code = entry
            else
              yield current_code, entry
              current_code = current_code ? current_code + 1 : nil
            end
          end
        end

        def glyph_for(char_code)
          result = nil
          each_difference do |code, name|
            result = name if code == char_code
          end
          result
        end
      end
    end
  end
end
