# PROPOSAL: FontResolver .ttc (TrueType Collection) support

## Summary

`Pdfrb::FontResolver` doesn't search for `.ttc` (TrueType Collection)
files. On macOS, many common fonts (Helvetica, Times New Roman, Courier,
Arial Unicode) are stored exclusively as `.ttc`. Without `.ttc` support,
the resolver returns `nil` for these fonts.

## Bug description

In `build_cache` (font_resolver.rb):

```ruby
Dir.glob("**/*.{ttf,otf}", base: dir).each do |rel_path|
```

The glob only matches `.ttf` and `.otf` files — `.ttc` is excluded.

## Reproduction

```ruby
resolver = Pdfrb::FontResolver.new
resolver.find(family: "Helvetica", style: "Regular")
# => nil  (should find /System/Library/Fonts/Helvetica.ttc)
```

On macOS:
- Helvetica is at `/System/Library/Fonts/Helvetica.ttc`
- Times New Roman is at `/System/Library/Fonts/Times New Roman.ttf` (works)
- Arial Unicode MS is at `/System/Library/Fonts/Supplemental/Arial Unicode.ttf` (works)
- Many system fonts are `.ttc` only

## Impact

The `idml` gem cannot use `Pdfrb::FontResolver` on macOS because many
fonts are `.ttc` only. It keeps the `Fontisan`-based resolver as a
fallback.

## Proposed fix

### 1. Add `.ttc` to glob

```ruby
Dir.glob("**/*.{ttf,otf,ttc}", base: dir).each do |rel_path|
```

### 2. Parse .ttc files

A `.ttc` file contains multiple fonts. The TTC header lists the offset
of each font's data within the file:

```
TTC Header:
  Tag: "ttcf"
  MajorVersion, MinorVersion
  numFonts: N
  offsetTable[N]: offsets to each font's data

Each font at its offset has a standard TTF/OTF structure.
```

For each `.ttc` file, parse the TTC header and iterate each font:

```ruby
def parse_font_info(path)
  data = File.binread(path)
  if data[0, 4] == "ttcf"
    parse_ttc(path, data)
  else
    parse_ttf(path, data)  # existing single-font parsing
  end
end

def parse_ttc(path, data)
  results = []
  num_fonts = data[8, 4].unpack1("N")
  num_fonts.times do |i|
    offset = data[12 + i * 4, 4].unpack1("N")
    info = parse_ttf_at_offset(path, data, offset)
    results << info if info
  end
  results
end
```

### 3. Register fonts from .ttc with Fonts#add

When registering a font from a `.ttc` file, the caller should specify
which font within the collection:

```ruby
# Option A: FontResolver returns the .ttc path + index
resolver.find(family: "Helvetica", style: "Regular")
# => { path: "/System/Library/Fonts/Helvetica.ttc", index: 0 }

# Option B: Fonts#add accepts a collection index
doc.fonts.add("/path/to/Helvetica.ttc", collection_index: 0)
```

## Priority

High — macOS is a primary development platform for the idml gem.
Without `.ttc` support, pdfrb's FontResolver is unusable on macOS for
common fonts.
