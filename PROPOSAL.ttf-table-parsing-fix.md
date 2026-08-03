# PROPOSAL: Fix TTF table parsing — table() returns raw bytes instead of parsed objects

## Summary

`Pdfrb::Font::TrueType::File#table("cmap")` returns a raw `String` of
table bytes instead of a parsed table object. This breaks
`Fonts#glyph_width`, `Fonts#glyph_widths`, `Fonts#measure_text`, and
`Fonts#extract_ttf_widths` for all TrueType/OpenType fonts.

## Bug description

In `extract_ttf_widths` (fonts.rb:380-400):

```ruby
ttf = Pdfrb::Font::TrueType::File.new(data)
cmap = ttf.table("cmap")     # Returns: String (raw bytes)
hmtx = ttf.table("hmtx")     # Returns: String (raw bytes)

gid = cmap.glyph_id_for(cp)  # ERROR: undefined method 'glyph_id_for' for String
```

`ttf.table("cmap")` returns the raw binary data of the cmap table as
a String, not a parsed `CmapTable` object with a `glyph_id_for` method.

## Reproduction

```ruby
require "pdfrb"
doc = Pdfrb::Document.new
font = doc.fonts.add("/System/Library/Fonts/Supplemental/Arial.ttf")
doc.fonts.glyph_width(font, 65)
# => 0  (should be ~667 for 'A' in Arial)
# Warning: pdfrb: could not extract TTF widths: undefined method
#          'glyph_id_for' for an instance of String
```

Standard 14 fonts (Helvetica, Times, Courier) work because they use
AFM data, not TTF parsing.

## Impact

- `glyph_width` / `glyph_widths` return 0 for all TTF/OTF fonts.
- `measure_text` returns 0 for TTF/OTF text.
- `metrics_for` returns empty hash for TTF/OTF fonts.
- Font width arrays in FontDescriptor are empty or wrong.
- Font embedding (FontFile2) may have incorrect /Widths array.

This blocks the `idml` gem from:
- Using pdfrb's measurement API (TODO 63)
- Replacing Fontisan (the idml gem keeps fontisan as a fallback)
- Producing correct PDFs with embedded TrueType fonts

## Proposed fix

`TrueType::File#table(name)` should return a parsed table object:

```ruby
class Pdfrb::Font::TrueType::File
  def table(name)
    entry = @tables[name]
    return nil unless entry

    data = @data[entry.offset, entry.length]
    parse_table(name, data)
  end

  def parse_table(name, data)
    case name
    when "cmap" then CmapTable.new(data)
    when "hmtx" then HmtxTable.new(data, @num_hmetrics)
    when "head" then HeadTable.new(data)
    when "hhea" then HheaTable.new(data)
    when "name" then NameTable.new(data)
    else data  # fallback: return raw bytes
    end
  end
end

class CmapTable
  def initialize(data)
    @data = data
    @subtables = parse_subtables(data)
  end

  def glyph_id_for(codepoint)
    @subtables.each do |sub|
      gid = sub.lookup(codepoint)
      return gid if gid && gid > 0
    end
    nil
  end
end

class HmtxTable
  def initialize(data, num_metrics)
    @widths = []
    num_metrics.times do |i|
      @widths[i] = data[i * 4, 2].unpack1("n")
    end
  end

  def width_for(glyph_id)
    @widths[glyph_id] || @widths.last || 0
  end
end
```

## Priority

**Critical** — this is the #1 bug blocking pdfrb adoption for the idml
gem. Without TTF parsing, glyph widths are wrong, text measurement
fails, and font embedding produces incorrect PDFs.
