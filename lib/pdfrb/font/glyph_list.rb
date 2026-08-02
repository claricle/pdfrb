# frozen_string_literal: true

module Pdfrb
  module Font
    # Adobe Glyph List — maps glyph names to Unicode codepoints.
    # Loaded from data/pdfrb/glyphlist.txt on first access.
    module GlyphList
      @table = nil

      class << self
        def table
          return @table if @table

          path = File.join(Pdfrb::DataDir.root, "glyphlist.txt")
          @table = if File.exist?(path)
                     parse(File.read(path, encoding: "UTF-8"))
                   else
                     {}
                   end
        end

        def [](glyph_name)
          table[glyph_name]
        end

        def unicode_for(glyph_name)
          table[glyph_name]
        end

        private

        def parse(text)
          text.each_line.with_object({}) do |line, h|
            next if line.start_with?("#")

            parts = line.strip.split(";")
            next unless parts.length >= 2

            name = parts[0]
            value = parts[1]
            # Glyphlist files come in two formats: Adobe's canonical
            # ("2013 2014" — hex codepoints space-separated) and
            # repackagings that use literal Unicode ("–"). Detect by
            # whether the value is all-hex.
            h[name] = if !value.empty? && value.match?(/\A[0-9A-Fa-f ]+\z/)
                        unicodes = value.split.map { |hex| hex.to_i(16) }
                        unicodes.map { |cp| [cp].pack("U") }.join
                      else
                        value
                      end
          end
        end
      end
    end
  end
end
