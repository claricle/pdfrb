# PROPOSAL: Canvas text measurement API

## Summary

Add `Document#fonts#measure_text(text, font:, size:)` returning the
rendered width in points. Enables callers to do line breaking, text
centering, and frame-fitting without a separate font metrics library.

## Motivation

The `idml` gem has its own text layout engine (`Idml::TextEngine`) with
a `FontMetrics` class that reads TTF tables via Fontisan. This is
necessary because pdfrb doesn't expose text measurement. If pdfrb
provided this, the idml gem could:

1. Remove the entire `Idml::TextEngine::FontMetrics` class (~200 lines).
2. Remove the `Fontisan` dependency.
3. Use pdfrb's own font data (which it already loads for `encode_text`).

## Proposed API

```ruby
# Measure the rendered width of a text string at a given font and size.
# @param text [String] the text to measure.
# @param font [Symbol] font resource name from Fonts#add.
# @param size [Float] font size in points.
# @return [Float] width in points.
def measure_text(text, font:, size:)
  afm = afm_for_font(font)
  return 0.0 unless afm

  scale = size / 1000.0
  text.each_char.sum { |char| (afm.widths[char] || 0) * scale }
end

# Get font metrics for a registered font.
# @param font [Symbol] font resource name.
# @return [Hash] { ascent:, descent:, cap_height:, x_height:, units_per_em: }
def metrics_for(font)
  afm = afm_for_font(font)
  return {} unless afm

  {
    ascent: afm.ascent,
    descent: afm.descent,
    cap_height: afm.cap_height,
    x_height: afm.x_height,
    units_per_em: 1000,
  }
end
```

## Implementation notes

pdfrb already loads AFM (Adobe Font Metrics) data for the 14 standard
Type1 fonts (`AFM_DIR`). For embedded TrueType fonts, the glyph widths
are in the font's `hmtx` table, which pdfrb parses during font loading.

The `measure_text` method would:
1. For standard fonts: use AFM width data (already loaded).
2. For embedded TrueType: use the glyph widths from `hmtx`.
3. For unknown fonts: return 0.0 or raise.

## Usage example

```ruby
font = doc.fonts.add("Helvetica")
width = doc.fonts.measure_text("Hello, World!", font: font, size: 12)
# => ~63.0 (points)

# Line breaking
frame_width = 200
words = text.split
line = +""
lines = []
words.each do |word|
  test = "#{line} #{word}".strip
  if doc.fonts.measure_text(test, font: font, size: 12) <= frame_width
    line = test
  else
    lines << line
    line = word
  end
end
lines << line if line.any?
```

## Priority

Medium — the idml gem has a workaround (its own FontMetrics), but
centralizing measurement in pdfrb reduces duplication and eliminates
the Fontisan dependency for idml consumers who don't need standalone
font parsing.
