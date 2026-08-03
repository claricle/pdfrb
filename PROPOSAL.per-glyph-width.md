# PROPOSAL: Per-glyph width measurement

## Summary

Add `Fonts#glyph_width(font, codepoint)` and `Fonts#glyph_widths(font,
codepoints)` for measuring individual glyph advance widths. Enables
text layout engines to do per-character shaping without parsing font
binary tables externally.

## Motivation

The `idml` gem has its own text layout engine (`Idml::TextEngine`) that
shapes text character-by-character via a `FontMetrics#glyph_width(cp)`
method. This requires parsing the TTF `hmtx` table via the `fontisan`
gem (~200 lines of binary parsing code).

pdfrb 0.18.0 has `Fonts#measure_text(text, font:, size:)` which measures
a full string. But for line breaking, the layout engine needs per-glyph
widths to know where word boundaries fall and how to distribute space
across justified lines.

## Proposed API

```ruby
# Measure the advance width of a single glyph at size 1000 (font units).
# @param font [Symbol] font resource name.
# @param codepoint [Integer] Unicode codepoint.
# @return [Integer] advance width in font units (not scaled by size).
def glyph_width(font, codepoint)
  # Look up glyph ID from cmap, then width from hmtx.
end

# Measure advance widths for multiple codepoints in one call.
# @param font [Symbol] font resource name.
# @param codepoints [Array<Integer>] Unicode codepoints.
# @return [Array<Integer>] widths in font units, one per codepoint.
def glyph_widths(font, codepoints)
  codepoints.map { |cp| glyph_width(font, cp) }
end
```

## Why not just measure_text per character?

`measure_text(char, font:, size:)` works but:
1. It returns a scaled `Float` (width in points at the given size).
   The layout engine needs unscaled `Integer` widths (font units) to
   avoid floating-point accumulation errors across many glyphs.
2. It's slower — each call goes through the full encoding + metrics
   pipeline. A batch `glyph_widths` call is more efficient.
3. It doesn't distinguish between "glyph not found" (width 0) and
   "glyph has width 0" (like space in some fonts).

## Implementation notes

pdfrb already parses the `cmap` and `hmtx` tables during font loading
(for `encode_text` and `measure_text`). The glyph width data is in
memory — `glyph_width` just needs to expose it.

For the 14 standard Type1 fonts, AFM data already has per-glyph widths.
For embedded TrueType/OpenType, the `hmtx` table has advance widths
indexed by glyph ID.

```ruby
def glyph_width(font, codepoint)
  font_data = font_data_for(font)
  return 0 unless font_data

  glyph_id = font_data.cmap_lookup(codepoint)
  font_data.advance_width(glyph_id)
end
```

## Usage example

```ruby
font = doc.fonts.add("/path/to/Arial.ttf")

# Per-glyph widths for line breaking
widths = doc.fonts.glyph_widths(font, "Hello World".each_codepoint.to_a)
# => [722, 556, 556, 556, 277, 0, 667, 556, 722, 556, 500]

# Text layout engine uses these for word-wrap
total = widths.sum  # => 5661 font units
width_at_12pt = total * 12.0 / 1000  # => 67.9 points
```

## Priority

Medium — `measure_text` is a workaround, but per-glyph widths eliminate
the need for `fontisan` in the `idml` gem and enable faster, more
accurate text layout.
