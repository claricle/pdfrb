# PROPOSAL: Font subsetting via used_codepoints

## Summary

Automatically subset embedded TrueType/OpenType fonts to include only
the glyphs actually used in the document. pdfrb 0.18.0 already tracks
`Fonts#used_codepoints` — extend this to drive the font subsetting
during serialization.

## Motivation

The `idml` gem embeds document fonts via `Fonts#add`. Without subsetting,
a 500KB Minion Pro font is embedded in full, even if only 50 glyphs are
used. Subsetting reduces this to ~5-15KB — a 30-100× reduction.

This is critical for:
- Web PDFs (smaller download)
- Email attachments (size limits)
- PDF/A compliance (font embedding is mandatory, but subsetting is best practice)
- Batch processing (many small PDFs)

## Current state in pdfrb 0.18.0

- `Fonts#used_codepoints` — tracks which Unicode codepoints have been
  encoded via `encode_text`. ✓
- `Fonts#embedded?` — checks if a font has FontFile2. ✓
- `Fonts#add` — registers fonts but may not subset by default.

## Proposed changes

### 1. Automatic subsetting on write

When `Document#write` serializes the PDF, for each embedded TrueType
font:

1. Get `used_codepoints` for the font resource.
2. Parse the TTF/OTF file's `glyf` (TrueType) or `CFF` (OpenType) table.
3. Build the glyph closure: used glyphs + their component glyphs
   (for composite glyphs) + `.notdef`.
4. Rebuild the font tables with only the needed glyphs.
5. Write the subsetted font as the FontFile2 stream.

### 2. Opt-in flag

```ruby
font = doc.fonts.add("/path/to/font.ttf", subset: true)
# ... render text ...
doc.write("output.pdf")  # FontFile2 contains only used glyphs
```

Default: `subset: true` (most callers want subsetting).

### 3. Subset prefix

Subsetting conventions use a 6-character uppercase prefix + `+` before
the font name (e.g., `ABCDEF+MinionPro-Regular`). This signals to PDF
processors that the font is a subset.

```ruby
# In the /BaseFont entry:
/BaseFont /ABCDEF+MinionPro-Regular
```

### 4. Fallback for invalid fonts

If subsetting fails (corrupt font, unsupported table structure), fall
back to full embedding and log a warning.

## Implementation notes

TrueType subsetting algorithm:
1. Collect used codepoint → glyph ID mappings from `cmap`.
2. Expand glyph closure: for each glyph, check if it's a composite
   (`.ttf` glyf table with `GF_COMPONENT` flag). Add component glyphs.
3. Rebuild `glyf`, `loca`, `maxp`, `hmtx`, `hhea`, `cmap`, `name`
   tables with only the needed glyphs.
4. Recompute checksums.

OpenType/CFF subsetting is more complex (CharStrings, Private DICT,
FDArray). Consider using a library like `ttf-rb` or porting the
algorithm from `fontTools.subset` (Python).

## Usage example

```ruby
doc = Pdfrb::Document.new
font = doc.fonts.add("/path/to/MinionPro-Regular.otf")
page = doc.pages.add
page.canvas.text("Hello, World!", at: [72, 720], font: font, size: 12)
doc.write("output.pdf")
# Only H, e, l, o, comma, space, W, r, d, ! glyphs are embedded
```

## Priority

High — font subsetting is the #1 remaining gap for production-quality
PDF output. Without it, every idml-generated PDF is 300-500KB larger
than necessary.
