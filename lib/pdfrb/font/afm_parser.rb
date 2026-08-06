# frozen_string_literal: true

module Pdfrb
  module Font
    # AFM (Adobe Font Metrics) parser. Reads the text-based AFM
    # format used by the 14 standard Type1 fonts.
    class AFMParser
      attr_reader :font_name, :full_name, :family_name,
                  :encoding_scheme, :bbox, :cap_height, :x_height,
                  :ascender, :descender, :italic_angle,
                  :average_width, :max_width, :char_metrics

      def initialize
        @char_metrics = {}
        @average_width = nil
        @max_width = nil
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
          in_char_metrics = parse_line(line, in_char_metrics)
        end
        self
      end

      def parse_line(line, in_char_metrics)
        return handle_state_change(line, in_char_metrics) if parse_global_metric(line) == :handled

        handle_state_change(line, in_char_metrics)
      end

      def handle_state_change(line, in_char_metrics)
        if line.start_with?("StartCharMetrics")
          true
        elsif line.start_with?("EndCharMetrics")
          compute_average_and_max_widths
          false
        elsif in_char_metrics && line.start_with?("C ")
          parse_char_metric(line)
          in_char_metrics
        else
          in_char_metrics
        end
      end

      def parse_global_metric(line)
        case line
        when /\AFontName / then @font_name = line.split(" ", 2)[1]
        when /\AFullName / then @full_name = line.split(" ", 2)[1]
        when /\AFamilyName / then @family_name = line.split(" ", 2)[1]
        when /\AEncodingScheme / then @encoding_scheme = line.split(" ", 2)[1]
        when /\AFontBBox / then @bbox = line.split.drop(1).map(&:to_f)
        when /\ACapHeight / then @cap_height = line.split[1].to_f
        when /\AXHeight / then @x_height = line.split[1].to_f
        when /\AAscender / then @ascender = line.split[1].to_f
        when /\ADescender / then @descender = line.split[1].to_f
        when /\AItalicAngle / then @italic_angle = line.split[1].to_f
        else return nil
        end
        :handled
      end

      def width_for(glyph_name_or_code)
        metric = @char_metrics[glyph_name_or_code] ||
                 @char_metrics[glyph_name_or_code.to_i]
        metric ? metric[:width] : 0
      end

      private

      def compute_average_and_max_widths
        widths = @char_metrics.values.filter_map { |m| m[:width] }
        return if widths.empty?

        @average_width = widths.sum / widths.length
        @max_width = widths.max
      end

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
