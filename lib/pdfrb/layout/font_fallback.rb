# frozen_string_literal: true

module Pdfrb
  module Layout
    # Glyph-level fallback: given a primary font and a chain of
    # fallback fonts (default CJK, Symbol, etc.), picks the first
    # font that can render the missing glyph. Returns the chosen
    # font name or nil if none can render.
    #
    # Coverage lookup uses the Standard 14 AFM glyph-name sets for
    # built-in fonts (Helvetica, Times-Roman, Courier, Symbol,
    # ZapfDingbats), and falls back to WinAnsi range coverage for
    # any other font.
    class FontFallback
      DEFAULT_CHAIN = %w[Helvetica Times-Roman Courier Symbol].freeze

      # Common Standard 14 AFM character-name sets, indexed by font
      # name. Each is a Set of glyph names the font defines. A
      # codepoint is "covered" if its Unicode-to-glyph-name lookup
      # yields a name in the set. Subset of full AFM data — covers
      # the Latin, Greek, and punctuation ranges needed for typical
      # prose.
      STANDARD14_GLYPH_NAMES = {
        "Helvetica" => %w[
          space exclam quotedbl numbersign dollar percent ampersand
          quoteright parenleft parenright asterisk plus comma minus
          period slash zero one two three four five six seven eight
          nine colon semicolon less equal greater question at A B C D
          E F G H I J K L M N O P Q R S T U V W X Y Z bracketleft
          backslash bracketright asciicircum underscore quoteleft a b
          c d e f g h i j k l m n o p q r s t u v w x y z braceleft
          bar braceright asciitilde
          Agrave Aacute Acircumflex Atilde Adieresis Aring AE Ccedilla
          Egrave Eacute Ecircumflex Edieresis Igrave Iacute Icircumflex
          Idieresis Eth Ntilde Ograve Oacute Ocircumflex Otilde Odieresis
          multiply Oslash Ugrave Uacute Ucircumflex Udieresis Yacute
          Thorn germandbls agrave aacute acircumflex atilde adieresis
          aring ae ccedilla egrave eacute ecircumflex edieresis igrave
          iacute icircumflex idieresis eth ntilde ograve oacute
          ocircumflex otilde odieresis divide oslash ugrave uacute
          ucircumflex udieresis yacute thorn ydieresis
        ].to_set.freeze,
        "Times-Roman" => %w[
          space exclam quotedbl numbersign dollar percent ampersand
          quoteright parenleft parenright asterisk plus comma minus
          period slash zero one two three four five six seven eight
          nine colon semicolon less equal greater question at A B C D
          E F G H I J K L M N O P Q R S T U V W X Y Z bracketleft
          backslash bracketright asciicircum underscore quoteleft a b
          c d e f g h i j k l m n o p q r s t u v w x y z braceleft
          bar braceright asciitilde
        ].to_set.freeze,
        "Courier" => %w[
          space exclam quotedbl numbersign dollar percent ampersand
          quoteright parenleft parenright asterisk plus comma minus
          period slash zero one two three four five six seven eight
          nine colon semicolon less equal greater question at A B C D
          E F G H I J K L M N O P Q R S T U V W X Y Z bracketleft
          backslash bracketright asciicircum underscore quoteleft a b
          c d e f g h i j k l m n o p q r s t u v w x y z braceleft
          bar braceright asciitilde
        ].to_set.freeze,
        "Symbol" => %w[
          Alpha Beta Chi Delta Epsilon Phi Gamma Eta Iota Theta Kappa
          Lambda Mu Nu Omicron Pi Rho Sigma Tau Upsilon Omega Xi Psi Zeta
          alpha beta chi delta epsilon phi gamma eta iota theta kappa
          lambda mu nu omicron pi rho sigma tau upsilon omega xi psi zeta
        ].to_set.freeze,
        "ZapfDingbats" => %w[
          a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16
        ].to_set.freeze,
      }.freeze

      # Unicode → Adobe glyph name lookup (subset). The full Adobe
      # Glyph List is ~2400 entries; this covers Latin + Greek
      # codepoints that the Standard 14 fonts handle.
      UNICODE_TO_GLYPH = {
        0x20 => "space", 0x21 => "exclam", 0x22 => "quotedbl",
        0x23 => "numbersign", 0x24 => "dollar", 0x25 => "percent",
        0x26 => "ampersand", 0x27 => "quoteright", 0x28 => "parenleft",
        0x29 => "parenright", 0x2A => "asterisk", 0x2B => "plus",
        0x2C => "comma", 0x2D => "minus", 0x2E => "period", 0x2F => "slash",
        0xC0 => "Agrave", 0xC1 => "Aacute", 0xC2 => "Acircumflex",
        0xC3 => "Atilde", 0xC4 => "Adieresis", 0xC5 => "Aring",
        0xC6 => "AE", 0xC7 => "Ccedilla", 0xC8 => "Egrave",
        0xC9 => "Eacute", 0xCA => "Ecircumflex", 0xCB => "Edieresis",
        0xCC => "Igrave", 0xCD => "Iacute", 0xCE => "Icircumflex",
        0xCF => "Idieresis", 0xD0 => "Eth", 0xD1 => "Ntilde",
        0xD2 => "Ograve", 0xD3 => "Oacute", 0xD4 => "Ocircumflex",
        0xD5 => "Otilde", 0xD6 => "Odieresis", 0xD8 => "Oslash",
        0xD9 => "Ugrave", 0xDA => "Uacute", 0xDB => "Ucircumflex",
        0xDC => "Udieresis", 0xDD => "Yacute", 0xDE => "Thorn",
        0xDF => "germandbls",
        0xE0 => "agrave", 0xE1 => "aacute", 0xE2 => "acircumflex",
        0xE3 => "atilde", 0xE4 => "adieresis", 0xE5 => "aring",
        0xE6 => "ae", 0xE7 => "ccedilla", 0xE8 => "egrave",
        0xE9 => "eacute", 0xEA => "ecircumflex", 0xEB => "edieresis",
        0xEC => "igrave", 0xED => "iacute", 0xEE => "icircumflex",
        0xEF => "idieresis", 0xF0 => "eth", 0xF1 => "ntilde",
        0xF2 => "ograve", 0xF3 => "oacute", 0xF4 => "ocircumflex",
        0xF5 => "otilde", 0xF6 => "odieresis", 0xF8 => "oslash",
        0xF9 => "ugrave", 0xFA => "uacute", 0xFB => "ucircumflex",
        0xFC => "udieresis", 0xFD => "yacute", 0xFE => "thorn",
        0xFF => "ydieresis",
        0x391 => "Alpha", 0x392 => "Beta", 0x393 => "Gamma",
        0x394 => "Delta", 0x395 => "Epsilon", 0x396 => "Zeta",
        0x397 => "Eta", 0x398 => "Theta", 0x399 => "Iota",
        0x39A => "Kappa", 0x39B => "Lambda", 0x39C => "Mu",
        0x39D => "Nu", 0x39E => "Xi", 0x39F => "Omicron",
        0x3A0 => "Pi", 0x3A1 => "Rho", 0x3A3 => "Sigma",
        0x3A4 => "Tau", 0x3A5 => "Upsilon", 0x3A6 => "Phi",
        0x3A7 => "Chi", 0x3A8 => "Psi", 0x3A9 => "Omega",
        0x3B1 => "alpha", 0x3B2 => "beta", 0x3B3 => "gamma",
        0x3B4 => "delta", 0x3B5 => "epsilon", 0x3B6 => "zeta",
        0x3B7 => "eta", 0x3B8 => "theta", 0x3B9 => "iota",
        0x3BA => "kappa", 0x3BB => "lambda", 0x3BC => "mu",
        0x3BD => "nu", 0x3BE => "xi", 0x3BF => "omicron",
        0x3C0 => "pi", 0x3C1 => "rho", 0x3C3 => "sigma",
        0x3C4 => "tau", 0x3C5 => "upsilon", 0x3C6 => "phi",
        0x3C7 => "chi", 0x3C8 => "psi", 0x3C9 => "omega"
      }.freeze

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
      # Standard 14 glyph-name sets for built-in fonts; for
      # non-standard fonts, assumes WinAnsi coverage up to 255.
      def covers?(font_name, codepoint)
        return true if codepoint < 128 # ASCII always covered

        standard14 = STANDARD14_GLYPH_NAMES[font_name.to_s]
        if standard14
          glyph = glyph_name_for(codepoint)
          return !!glyph && standard14.include?(glyph)
        end

        winansi?(codepoint)
      end

      private

      def glyph_name_for(codepoint)
        # Single-codepoint entries in UNICODE_TO_GLYPH.
        return UNICODE_TO_GLYPH[codepoint] if UNICODE_TO_GLYPH.key?(codepoint)

        # Ranges that map to ASCII letters/digits — all share the
        # ASCII character as glyph name. Grouped to avoid rubocop
        # duplicate-branch warnings.
        case codepoint
        when 0x30..0x39, 0x41..0x5A, 0x61..0x7A then codepoint.chr
        end
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
