# frozen_string_literal: true

module Pdfrb
  module Layout
    # Immutable typographic + visual style. Updating a property
    # returns a new Style; the original is unchanged.
    #
    # Built-in presets (:base, :title, :heading1, :heading2, :heading3,
    # :code, :caption) can be loaded via +Style.new(:heading1)+ or
    # merged via +Style.new(base: :heading1, **overrides)+.
    class Style
      PROPERTIES = %i[
        font_name font_size font_options fill_color stroke_color
        fill_alpha stroke_alpha line_width line_spacing character_spacing
        word_spacing text_align vertical_align text_rendering_mode
        text_rise font_features text_decoration text_underline_color
        subscript superscript border padding margin border_color
        border_style border_radius background background_alpha
        overlap_overflow_alpha position text_transform word_break
        hyphenate language first_line_indent text_indent
      ].freeze

      PRESETS = {
        base: { font_name: "Helvetica", font_size: 10, line_spacing: 1.2,
                fill_color: [0, 0, 0] },
        title: { font_name: "Helvetica-Bold", font_size: 24,
                 fill_color: [0, 0, 0] },
        heading1: { font_name: "Helvetica-Bold", font_size: 20,
                    fill_color: [0, 0, 0] },
        heading2: { font_name: "Helvetica-Bold", font_size: 16 },
        heading3: { font_name: "Helvetica-BoldOblique", font_size: 14 },
        code: { font_name: "Courier", font_size: 10 },
        caption: { font_name: "Helvetica-Oblique", font_size: 9,
                   fill_color: [0.3, 0.3, 0.3] },
      }.freeze

      def initialize(name_or_base = nil, **opts)
        base = if name_or_base.is_a?(Hash)
                 name_or_base
               elsif name_or_base.is_a?(Symbol)
                 PRESETS[name_or_base] || {}
               else
                 {}
               end
        @values = base.merge(opts).freeze
      end

      def update(**opts)
        self.class.new(@values.merge(opts))
      end
      alias dup_with update

      def to_h
        @values.dup
      end

      PROPERTIES.each do |prop|
        define_method(prop) { @values[prop] }
      end
    end
  end
end
