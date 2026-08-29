# frozen_string_literal: true

module Pdfrb
  module FontLoader
    # Type3 font loader. Type3 fonts define glyphs as PDF drawing
    # procedures (content streams) rather than outlines. Used for
    # custom symbol sets and pixel-art fonts.
    #
    # Each glyph is a (name, width, procedure) triple where the
    # procedure is a content stream drawing in a 1000x1000 glyph
    # grid. The loader emits a /Type /Font /Subtype /Type3 font dict
    # with /CharProcs mapping glyph names to streams.
    class Type3
      GlyphSpec = Struct.new(:name, :width, :procedure, keyword_init: true)

      attr_reader :document, :glyphs, :bounding_box, :matrix

      # @param document [Pdfrb::Document] the document to embed in.
      # @param glyphs [Array<GlyphSpec>] glyph definitions.
      # @param bounding_box [Array<Numeric>] 4-number BBox.
      # @param matrix [Array<Numeric>, nil] 6-number FontMatrix
      #   (default: [0.001 0 0 0.001 0 0]).
      def initialize(document:, glyphs:, bounding_box:, matrix: nil)
        @document = document
        @glyphs = glyphs
        @bounding_box = bounding_box
        @matrix = matrix || [0.001, 0, 0, 0.001, 0, 0]
      end

      # Build and return the Type3 font dictionary. Each glyph
      # procedure becomes an indirect stream object referenced
      # from /CharProcs.
      def build
        char_procs = {}
        widths = []
        encoding = { Type: :Encoding, Differences: [] }

        glyphs.each_with_index do |glyph, i|
          code = 32 + i
          stream = document.add({ Length: glyph.procedure.bytesize },
                                type: Pdfrb::Model::Cos::Stream)
          stream.stream = glyph.procedure
          char_procs[glyph.name.to_sym] = stream.ref
          widths[code] = glyph.width
          encoding[:Differences] << code << glyph.name.to_sym
        end

        document.add(
          {
            Type: :Font,
            Subtype: :Type3,
            FontBBox: bounding_box,
            FontMatrix: matrix,
            CharProcs: char_procs,
            Encoding: encoding,
            FirstChar: 32,
            LastChar: 31 + glyphs.length,
            Widths: widths,
          },
          type: Pdfrb::Model::Type::Font
        )
      end
    end
  end
end
