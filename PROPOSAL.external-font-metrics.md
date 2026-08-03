# PROPOSAL: Accept externally-provided font metrics in Fonts#add

## Summary

Allow `Fonts#add` to accept pre-parsed font metrics (glyph widths,
ascent/descent, encoding) from the caller, instead of requiring pdfrb
to parse TTF/OTF binary tables internally. This lets consumers use
well-tested font parsers (like Fontisan) and pass the results to pdfrb.

## Motivation

pdfrb's internal TTF table parser (`TrueType::File#table`) is broken
— it returns raw `String` bytes instead of parsed table objects, causing
`glyph_id_for` to fail for all TrueType/OpenType fonts. This breaks
`glyph_width`, `measure_text`, `metrics_for`, and font width arrays.

Fontisan (used by the `idml` gem) correctly parses all TTF tables
(cmap, hmtx, head, hhea, name) and provides per-glyph widths, metrics,
and encoding. It is battle-tested across hundreds of font files.

Instead of pdfrb reimplementing TTF parsing (and getting it wrong),
pdfrb should accept externally-provided metrics. This follows the
Unix philosophy: do one thing well. pdfrb assembles PDFs; Fontisan
parses fonts.

## Proposed API

```ruby
# Register a font with externally-provided metrics.
# @param name_or_io [String, IO] font file path or IO (for FontFile2
#   embedding — pdfrb reads the raw bytes, does NOT parse tables).
# @param widths [Hash{Integer => Integer}, nil] codepoint → advance
#   width in font units. Required for correct text width measurement.
# @param metrics [Hash, nil] font-level metrics:
#   { units_per_em:, ascent:, descent:, cap_height:, x_height: }
# @param encoding [Hash{Integer => Integer}, nil] codepoint → glyph ID
#   mapping (from cmap table). Used for encode_text.
# @param subset [Boolean] if true, subset during write using
#   used_codepoints.
# @return [Symbol] font resource name.
def add(name_or_io, widths: nil, metrics: nil, encoding: nil,
        subset: nil, **opts)
```

When `widths:` is provided, pdfrb uses it instead of calling the broken
`extract_ttf_widths`. When `metrics:` is provided, `metrics_for` returns
it instead of an empty hash. When `encoding:` is provided, `encode_text`
uses it instead of the broken cmap parser.

## Usage with Fontisan

```ruby
require "fontisan"
require "pdfrb"

# Parse font with Fontisan (correct, tested)
font_path = "/path/to/Arial.ttf"
fontisan = Fontisan::FontLoader.load(font_path)

# Extract metrics via Fontisan
metrics = {
  units_per_em: fontisan.head.units_per_em,
  ascent: fontisan.hhea.ascent,
  descent: fontisan.hhea.descent,
}
widths = fontisan.hmtx.advance_widths  # {glyph_id => width}
encoding = fontisan.cmap.code_map       # {codepoint => glyph_id}

# Register with pdfrb using externally-provided data
doc = Pdfrb::Document.new
font = doc.fonts.add(font_path,
                     widths: widths,
                     metrics: metrics,
                     encoding: encoding)

# Now glyph_width, measure_text, metrics_for all work correctly
doc.fonts.glyph_width(font, 65)  # => 667 (for 'A')
doc.fonts.measure_text("Hello", font: font, size: 12)  # => ~28.0
```

## Usage from the idml gem

The `idml` gem already has `FontMetrics` (Fontisan-based) that provides
`glyph_width(codepoint)`, `units_per_em`, `ascent`, `descent`. It would
build the `widths:` and `metrics:` hashes from FontMetrics and pass them
to pdfrb:

```ruby
# In Idml::Render::Pipeline
metrics = Idml::TextEngine::FontMetrics.open(font_path)
widths = {}
(32..255).each { |cp| widths[cp] = metrics.glyph_width(cp) }

font_name = writer.register_font_with_metrics(
  font_path,
  widths: widths,
  metrics: { units_per_em: metrics.units_per_em,
             ascent: metrics.ascent,
             descent: metrics.descent },
)
```

## Implementation notes

1. Store `widths`, `metrics`, `encoding` alongside the font registration.
2. In `glyph_width(font, codepoint)`: if external widths provided,
   return `widths[codepoint] || 0`. Otherwise fall back to AFM (standard
   14) or the internal TTF parser.
3. In `metrics_for(font)`: if external metrics provided, return them.
   Otherwise fall back to AFM or internal parser.
4. In `encode_text(text, font)`: if external encoding provided, use it
   for codepoint → glyph ID mapping. Otherwise fall back to existing
   encoding.
5. FontFile2 embedding reads the raw file bytes (pdfrb already does
   this correctly — the bug is only in table *parsing*, not file reading).

## What pdfrb should NOT do

- Parse TTF/OTF tables internally — this is Fontisan's job.
- Depend on Fontisan — pdfrb should remain dependency-free for font
  parsing. The caller decides which parser to use.
- Reimplement cmap/hmtx/head/hhea/name parsing — these are complex
  binary formats with many edge cases that Fontisan handles correctly.

## Priority

**Critical** — this unblocks TODOs 52 and 63 in the idml gem. Without
external metrics support, the idml gem cannot use pdfrb's measurement
API and must keep its entire text engine separate from pdfrb.
