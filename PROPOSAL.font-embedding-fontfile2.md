# PROPOSAL: Font embedding verification and FontFile2 output

## Summary

Ensure `Fonts#add` produces a `/FontFile2` (or `/FontFile3`) stream
in the output PDF when a TrueType/OpenType font file is passed. Add
a `Fonts#embedded?` query and log warnings when embedding fails.

## Motivation

The `idml` gem registers document fonts via `document.fonts.add(path)`.
The returned resource name works for `canvas.text`, but the output PDF
does not contain `/FontFile2`. This means:
- Text renders correctly only on systems with the font installed.
- The PDF is not self-contained.
- PDF/A compliance (which requires all fonts embedded) is impossible.

Testing with `/System/Library/Fonts/Supplemental/Arial.ttf`:
```ruby
doc = Pdfrb::Document.new
doc.fonts.add("/System/Library/Fonts/Supplemental/Arial.ttf")
# Output PDF has /BaseFont but no /FontFile2
```

## Root cause analysis

Looking at `Fonts#add`, the code path for TrueType fonts calls
`register_font(resource, name, name_or_io, **opts)`. This method
may not be creating the FontDescriptor + FontFile2 objects for
all font types. The standard 14 Type1 fonts don't need embedding,
but TrueType (.ttf) and OpenType (.otf) files should be embedded
as FontFile2 / FontFile3 respectively.

## Proposed changes

### 1. Ensure FontFile2 for TrueType

When `name_or_io` is a `.ttf` file path or IO:
1. Read the font data.
2. Create a stream object with the raw TTF bytes.
3. Create a FontDescriptor with `/FontFile2` pointing to the stream.
4. Set the Font dictionary's `/FontDescriptor` to the FontDescriptor.

### 2. Add `Fonts#embedded?(resource)` query

```ruby
def embedded?(resource)
  entry = @font_entries[resource]
  return false unless entry

  entry[:font_descriptor]&.value&.key?(:FontFile2) ||
    entry[:font_descriptor]&.value&.key?(:FontFile3)
end
```

### 3. Log warning on embedding failure

When embedding is requested but fails (corrupt font, unsupported
format), log a warning:

```ruby
Pdfrb.logger.warn("Failed to embed font #{name}: #{e.message}")
```

### 4. Font subsetting (stretch goal)

Embed only the glyphs actually used:
1. Collect used codepoints from `encode_text` calls.
2. Subset the TTF using a glyph table parser.
3. Embed the subsetted font as FontFile2.

This reduces a 500KB font to ~5-20KB in the PDF.

## Usage example

```ruby
font = doc.fonts.add("/path/to/MinionPro-Regular.otf")
doc.fonts.embedded?(font)  # => true (after this proposal)

page = doc.pages.add
page.canvas.text("Hello", at: [72, 720], font: font, size: 12)
# PDF now contains /FontFile2 with the font data
```

## Priority

High — without font embedding, the PDF is not portable. This is the
#1 gap for the idml gem's rendering pipeline.
