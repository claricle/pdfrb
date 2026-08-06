# frozen_string_literal: true

module Pdfrb
  module Font
    # Metrics value object + lookup helper. Returns ascent/descent/
    # cap_height/x_height/line_gap/avg_width for any font (Standard 14
    # via AFM, embedded TTF/OTF via head/hhea/OS2 tables).
    Metrics = Struct.new(:font_name, :units_per_em, :ascent, :descent,
                         :cap_height, :x_height, :line_gap, :avg_width,
                         :max_width, :stem_v, :italic_angle, :bbox,
                         keyword_init: true) do
      def line_height(font_size)
        ((ascent || 800) - (descent || -200) + (line_gap || 0)) *
          font_size.to_f / (units_per_em || 1000)
      end

      def ascender(font_size)
        (ascent || 800) * font_size.to_f / (units_per_em || 1000)
      end

      def descender(font_size)
        (descent || -200) * font_size.to_f / (units_per_em || 1000)
      end
    end

    module MetricsHelper
      module_function

      # Look up metrics for a Standard 14 font name.
      # @param font_name [String, Symbol] e.g., "Helvetica", "Times-Roman".
      # @return [Pdfrb::Font::Metrics, nil]
      def metrics_for_standard14(font_name)
        afm = afm_for(font_name.to_s)
        return nil unless afm

        Metrics.new(
          font_name: font_name.to_s,
          units_per_em: 1000,
          ascent: afm.ascender,
          descent: afm.descender,
          cap_height: afm.cap_height,
          x_height: afm.x_height,
          line_gap: 0,
          avg_width: afm.average_width,
          max_width: afm.max_width,
          stem_v: 80,
          italic_angle: afm.italic_angle || 0,
          bbox: afm.bbox
        )
      rescue StandardError
        nil
      end

      # Look up metrics from raw TTF/OTF bytes.
      # @param font_data [String] raw TTF or OTF bytes.
      # @return [Pdfrb::Font::Metrics, nil]
      def metrics_for_ttf(font_data)
        return nil unless font_data && font_data.bytesize >= 4

        ttf = Pdfrb::Font::TrueType::File.new(font_data)
        head = ttf.head_table_parsed
        hhea = ttf.hhea_table_parsed
        os2 = ttf.os2_table_parsed
        return nil unless head && hhea

        Metrics.new(
          font_name: ttf.name_table_parsed&.ps_name || "EmbeddedFont",
          units_per_em: head.units_per_em || 1000,
          ascent: hhea.ascender || os2&.s_typo_ascender || 800,
          descent: hhea.descender || os2&.s_typo_descender || -200,
          cap_height: os2&.s_cap_height || 700,
          x_height: 500,
          line_gap: hhea.line_gap || 0,
          avg_width: 500,
          max_width: hhea.advance_width_max || 1000,
          stem_v: 80,
          italic_angle: (head.italic? ? -12 : 0),
          bbox: head.bbox
        )
      rescue StandardError
        nil
      end

      # Convenience: dispatch on font_name vs raw bytes.
      def metrics_for(font_name_or_data)
        case font_name_or_data
        when String
          if font_name_or_data.bytesize >= 4 && valid_magic?(font_name_or_data)
            metrics_for_ttf(font_name_or_data)
          else
            metrics_for_standard14(font_name_or_data)
          end
        when Symbol then metrics_for_standard14(font_name_or_data)
        end
      end

      def valid_magic?(bytes)
        magic = bytes.byteslice(0, 4)
        ["\x00\x01\x00\x00".b, "OTTO".b, "true".b, "ttcf".b].include?(magic)
      end

      def afm_for(name)
        @afm_cache ||= {}
        return @afm_cache[name] if @afm_cache.key?(name)

        path = standard14_afm_path(name)
        return @afm_cache[name] = nil unless path && File.exist?(path)

        @afm_cache[name] = Pdfrb::Font::AFMParser.parse(File.read(path))
      end

      def standard14_afm_path(name)
        # __dir__ is lib/pdfrb/font/. Three .. gets to project root
        # (lib/pdfrb/font → lib/pdfrb → lib → project root). Data
        # files live at <root>/data/pdfrb/afm/.
        base = File.expand_path("../../../data/pdfrb/afm", __dir__)
        File.join(base, "#{name}.afm")
      end
    end
  end
end
