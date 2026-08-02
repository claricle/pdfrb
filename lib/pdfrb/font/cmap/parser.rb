# frozen_string_literal: true

module Pdfrb
  module Font
    module CMap
      # Minimal CMap text parser. Extracts +begincodespacerange+,
      # +beginbfchar+, +beginbfrange+ sections into a simple Hash
      # mapping source codes to target Unicode strings.
      class Parser
        attr_reader :cmap_name, :system_info, :codespace, :bfchar, :bfrange

        def initialize
          @codespace = []
          @bfchar = {}
          @bfrange = []
        end

        def self.parse(text)
          new.tap { |p| p.parse(text) }
        end

        def parse(text)
          text.each_line do |line|
            stripped = line.strip
            case stripped
            when /\/CMapName\s+\/(\S+)/ then @cmap_name = Regexp.last_match(1)
            when /\Abegincodespacerange/
              read_section(text, line, :codespacerange)
            end
          end
          parse_bfchar_sections(text)
          parse_bfrange_sections(text)
        end

        def decode(code)
          @bfchar[code]
        end

        private

        def read_section(text, start_line, kind)
          # Minimal — a full CMap parser needs state tracking.
        end

        def parse_bfchar_sections(text)
          lines = text.each_line.to_a
          i = 0
          while i < lines.length
            if lines[i].strip =~ /beginbfchar\b/
              i += 1
              until lines[i]&.strip == "endbfchar"
                pair = lines[i].strip.split(/\s+/)
                if pair.length >= 2
                  key = hex_to_int(pair[0])
                  val = hex_to_utf16(pair[1])
                  @bfchar[key] = val
                end
                i += 1
              end
            end
            i += 1
          end
        end

        def parse_bfrange_sections(text)
          # Simplified: parse `<start> <end> <target>` lines.
          text.each_line do |line|
            m = line.strip.match(/<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>/)
            next unless m

            start_code = m[1].to_i(16)
            end_code = m[2].to_i(16)
            target_start = m[3].to_i(16)
            (start_code..end_code).each_with_index do |code, idx|
              cp = target_start + idx
              @bfchar[code] = [cp].pack("U") if cp <= 0x10FFFF
            end
          end
        end

        def hex_to_int(str)
          str.sub(/\A</, "").sub(/>\z/, "").to_i(16)
        end

        def hex_to_utf16(str)
          raw = str.sub(/\A</, "").sub(/>\z/, "")
          codepoints = raw.scan(/.{4}/).map { |h| h.to_i(16) }
          decode_surrogates(codepoints)
        end

        def decode_surrogates(codepoints)
          result = +""
          i = 0
          while i < codepoints.length
            cp = codepoints[i]
            if cp.between?(0xD800, 0xDBFF) && i + 1 < codepoints.length &&
                codepoints[i + 1] >= 0xDC00 && codepoints[i + 1] <= 0xDFFF
              combined = 0x10000 + ((cp - 0xD800) << 10) + (codepoints[i + 1] - 0xDC00)
              result << combined
              i += 2
            else
              result << cp
              i += 1
            end
          end
          result
        end
      end
    end
  end
end
