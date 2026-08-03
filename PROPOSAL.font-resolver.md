# PROPOSAL: Font file resolver

## Summary

Add `Pdfrb::FontResolver` that searches system font directories for
font files by family name + style. Eliminates the need for external
font-finding libraries (like `fontisan` in the `idml` gem).

## Motivation

The `idml` gem uses `Fontisan` to:
1. Search `/System/Library/Fonts`, `/Library/Fonts`, `~/Library/Fonts`,
   `/usr/share/fonts`, `~/.local/share/fonts` for `.ttf`/`.otf` files.
2. Parse each file's `name` table to get PostScript name, family name,
   style name.
3. Match by family + style (e.g., "Minion Pro" + "Regular" →
   "MinionPro-Regular").
4. Return the file path.

This is ~100 lines of `fontisan`-dependent code. If pdfrb provided font
resolution, the `idml` gem could drop the `fontisan` dependency entirely.

## Proposed API

```ruby
module Pdfrb
  class FontResolver
    DEFAULT_SEARCH_PATHS = [
      "/System/Library/Fonts",
      "/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "/usr/share/fonts",
      File.expand_path("~/.local/share/fonts"),
    ].freeze

    # @param search_paths [Array<String>] directories to search.
    def initialize(search_paths: DEFAULT_SEARCH_PATHS)
    end

    # Find a font file by family name and optional style.
    # @param family [String] e.g., "Arial", "Minion Pro"
    # @param style [String] e.g., "Regular", "Bold", "Italic"
    # @return [String, nil] file path, or nil if not found.
    def find(family:, style: "Regular")
    end

    # Find by PostScript name (exact match).
    # @param ps_name [String] e.g., "ArialMT", "MinionPro-Regular"
    # @return [String, nil] file path.
    def find_by_ps_name(ps_name)
    end

    # List all available font files in search paths.
    # @return [Array<Hash>] [{ path:, family:, style:, ps_name: }, ...]
    def available_fonts
    end
  end
end
```

## Implementation notes

pdfrb already parses font `name` tables during `Fonts#add`. The resolver
would:

1. Glob `**/*.{ttf,otf,ttc}` in each search path.
2. For each file, parse the `name` table to get family/style/PS name.
3. Cache results (font directory scanning is expensive).
4. Match by family + style with fuzzy matching (e.g., "Bold Italic"
   matches "BoldItalic").

For `.ttc` (TrueType Collection) files, each file contains multiple
fonts. The resolver should iterate all fonts within the collection.

Platform-specific paths:
- macOS: `/System/Library/Fonts`, `/Library/Fonts`, `~/Library/Fonts`
- Linux: `/usr/share/fonts`, `/usr/local/share/fonts`, `~/.local/share/fonts`, `~/.fonts`
- Windows: `C:\Windows\Fonts`

## Usage example

```ruby
resolver = Pdfrb::FontResolver.new
path = resolver.find(family: "Minion Pro", style: "Regular")
# => "/Library/Fonts/MinionPro-Regular.otf"

font = doc.fonts.add(path)
page = doc.pages.add
page.canvas.text("Hello", at: [72, 720], font: font, size: 12)
```

## Priority

Medium — eliminates the `fontisan` dependency for pdfrb consumers.
The `idml` gem's entire `FontResolver` + `FontMetrics` classes
(~300 lines) could be replaced by pdfrb's resolver + measurement.
