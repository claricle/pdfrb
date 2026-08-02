# frozen_string_literal: true

module Pdfrb
  module Font
    # AFM (Adobe Font Metrics) parser. Reads the text-based AFM
    # format used by the 14 standard Type1 fonts.
    class AFMParser
      attr_reader :font_name, :full_name, :family_name,
                  :encoding_scheme, :bbox, :cap_height, :x_height,
                  :ascender, :descender, :char_metrics

      def initialize
        @char_metrics = {}
      end

      def self.parse(text)
        new.tap { |p| p.parse(text) }
      end

      def self.from_file(path)
        parse(File.read(path, encoding: "UTF-8"))
      end

      def parse(text)
        in_char_metrics = false
        text.each_line do |line|
          line = line.strip
          if line.start_with?("FontName ")
            @font_name = line.split(" ", 2)[1]
          elsif line.start_with?("FullName ")
            @full_name = line.split(" ", 2)[1]
          elsif line.start_with?("FamilyName ")
            @family_name = line.split(" ", 2)[1]
          elsif line.start_with?("EncodingScheme ")
            @encoding_scheme = line.split(" ", 2)[1]
          elsif line.start_with?("FontBBox ")
            @bbox = line.split.drop(1).map(&:to_f)
          elsif line.start_with?("CapHeight ")
            @cap_height = line.split[1].to_f
          elsif line.start_with?("XHeight ")
            @x_height = line.split[1].to_f
          elsif line.start_with?("Ascender ")
            @ascender = line.split[1].to_f
          elsif line.start_with?("Descender ")
            @descender = line.split[1].to_f
          elsif line == "StartCharMetrics" || line.start_with?("StartCharMetrics ")
            in_char_metrics = true
          elsif line == "EndCharMetrics" || line.start_with?("EndCharMetrics")
            in_char_metrics = false
          elsif in_char_metrics && line.start_with?("C ")
            parse_char_metric(line)
          end
        end
        self
      end

      def width_for(glyph_name_or_code)
        metric = @char_metrics[glyph_name_or_code] ||
                 @char_metrics[glyph_name_or_code.to_i]
        metric ? metric[:width] : 0
      end

      private

      def parse_char_metric(line)
        parts = line.split(";").map(&:strip)
        code = nil
        width = 0
        name = nil
        parts.each do |part|
          kv = part.split(" ", 2)
          case kv[0]
          when "C" then code = kv[1].to_i
          when "WX" then width = kv[1].to_f
          when "N" then name = kv[1]
          end
        end
        metric = { code: code, width: width, name: name }
        @char_metrics[code] = metric if code && code >= 0
        @char_metrics[name] = metric if name
      end
    end
  end
end
