# frozen_string_literal: true

module Pdfrb
  module Layout
    # Glyph-level fallback: given a primary font and a chain of
    # fallback fonts (default CJK, Symbol, etc.), picks the first
    # font that can render the missing glyph. Returns the chosen
    # font name or nil if none can render.
    #
    # The probe interface is intentionally narrow: a font's
    # +covers?(codepoint)+ class method returns true/false. Built-in
    # fonts (Helvetica, Times-Roman, Courier) cover WinAnsi codepoints
    # by default; TrueType fonts use the cmap table.
    class FontFallback
      DEFAULT_CHAIN = %w[Helvetica Times-Roman Courier Symbol].freeze

      attr_reader :chain

      # @param chain [Array<String>] ordered list of font names to
      #   try when the primary can't render a glyph.
      def initialize(chain: DEFAULT_CHAIN)
        @chain = chain
      end

      # Find a font in the chain that covers +codepoint+.
      # @return [String, nil] font name, or nil if none match.
      def pick(codepoint, primary: nil)
        return primary if primary && covers?(primary, codepoint)

        @chain.find { |name| covers?(name, codepoint) }
      end

      # Reshape +text+ into segments, each tagged with the font that
      # renders it. Returns an Array of [font_name, substring] pairs.
      # Adjacent segments that share the same font are merged.
      def segment(text, primary: nil)
        return [[primary, text]] if text.to_s.empty?

        segments = []
        current_font = nil
        current_chars = +""

        text.to_s.each_codepoint do |cp|
          ch = cp.chr(Encoding::UTF_8)
          font = pick(cp, primary: primary)
          if font == current_font
            current_chars << ch
          else
            segments << [current_font, current_chars] if current_chars.length.positive?
            current_font = font
            current_chars = ch.to_s
          end
        end
        segments << [current_font, current_chars] if current_chars.length.positive?
        segments
      end

      # Whether +font_name+ can render +codepoint+. Uses the
      # Standard 14 AFM coverage for built-in fonts; for TrueType
      # fonts (loaded via Document::Fonts), falls back to ASCII range.
      def covers?(font_name, codepoint)
        return true if codepoint < 128 # ASCII always covered
        return true if standard_font_covers?(font_name, codepoint)

        # Non-standard fonts: assume WinAnsi coverage up to 255.
        codepoint <= 255
      end

      private

      def standard_font_covers?(font_name, codepoint)
        return false unless Pdfrb::Document::Fonts::STANDARDS.include?(font_name.to_s)
        return false if font_name.to_s == "Symbol"
        return false if font_name.to_s == "ZapfDingbats"

        # Standard fonts cover WinAnsi range.
        winansi?(codepoint)
      end

      def winansi?(codepoint)
        return true if codepoint < 0x80
        return true if (0xA0..0xFF).cover?(codepoint)
        return true if [0x20AC, 0x201A, 0x0192, 0x201E, 0x2026,
                        0x2020, 0x2021, 0x02C6, 0x2030].include?(codepoint)

        false
      end
    end
  end
end
