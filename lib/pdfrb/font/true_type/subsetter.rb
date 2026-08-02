# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # Glyph subsetting for embedded TrueType fonts. Given a set of
      # used glyph IDs, produces a new TTF with only those glyphs.
      # This is a stub — full subsetting (table rewriting, composite
      # glyph handling, CMap format 4 rewrite) is complex.
      class Subsetter
        attr_reader :source_file, :glyph_ids

        def initialize(source_file, glyph_ids)
          @source_file = source_file
          @glyph_ids = glyph_ids.sort.uniq
        end

        # Returns the subset font bytes. Currently a stub that
        # returns the original file unmodified (no subsetting).
        # Full implementation would rewrite glyf, loca, cmap, hmtx,
        # maxp, OS/2 tables.
        def subset
          @source_file.instance_variable_get(:@data)
        end
      end
    end
  end
end
