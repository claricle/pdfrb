# frozen_string_literal: true

module Pdfrb
  module Font
    module Type1
      # Type1 font metrics wrapper. Delegates to AFMParser for the
      # 14 standard fonts; provides glyph-width lookup.
      class FontMetrics
        attr_reader :font_name, :metrics

        def initialize(font_name, metrics)
          @font_name = font_name
          @metrics = metrics
        end

        def self.for_standard_font(name)
          afm_path = File.join(Pdfrb::DataDir.root, "afm", "#{name}.afm")
          return nil unless File.exist?(afm_path)

          metrics = AFMParser.from_file(afm_path)
          new(name, metrics)
        end

        def width_for(glyph_name)
          @metrics.width_for(glyph_name)
        end

        def bbox
          @metrics.bbox
        end

        def ascender
          @metrics.ascender
        end

        def descender
          @metrics.descender
        end

        def cap_height
          @metrics.cap_height
        end
      end
    end
  end
end
