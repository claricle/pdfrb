# frozen_string_literal: true

module Pdfrb
  module Layout
    # Text shaping interface. Pure-Ruby shapers don't exist for the
    # complexity of OpenType GSUB/GPOS — this module defines the
    # contract that a real shaper (HarfBuzz, fribidi, etc.) must
    # satisfy. Callers can plug in a shaper implementation via
    # Pdfrb::Layout::TextShaper.implementation = MyShaper.
    #
    # The default implementation is a no-op pass-through that returns
    # the input string unchanged. TextLayouter falls back to it when
    # no real shaper is registered.
    module TextShaper
      @implementation = nil

      ShapedRun = Struct.new(:codepoints, :clusters, :advances, keyword_init: true)

      class << self
        attr_accessor :implementation

        # Shape +text+ for +font+ at +size+. Returns a ShapedRun
        # whose codepoints array contains the reordered/substituted
        # codepoint sequence, clusters maps each glyph to its source
        # cluster index, and advances holds per-glyph x-advance.
        #
        # If no implementation is registered, returns the raw
        # codepoints with simple per-glyph advances (assumes 1em
        # average width).
        def shape(text, font: nil, size: 12, direction: :ltr)
          if implementation
            return implementation.shape(text, font: font, size: size,
                                              direction: direction)
          end

          default_shape(text, size, direction)
        end

        private

        def default_shape(text, size, _direction)
          cps = text.to_s.codepoints.to_a
          clusters = (0...cps.length).to_a
          advances = cps.map { size / 2.0 }
          ShapedRun.new(codepoints: cps, clusters: clusters, advances: advances)
        end
      end
    end
  end
end
