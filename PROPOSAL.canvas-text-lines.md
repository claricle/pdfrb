# PROPOSAL: Canvas multi-line text helper

## Summary

Add `Canvas#text_lines(lines, font:, size:, leading:, at:)` for drawing
multiple lines of text with consistent leading. Simplifies multi-line
text rendering that currently requires N separate `text` calls.

## Motivation

The `idml` gem's `TextFrameRenderer` breaks text into lines via a line
breaker, then calls `canvas.text` once per line at a manually computed
y position:

```ruby
lines.each do |line|
  canvas.text(line.text, at: [x, baseline_y], font: font, size: size)
  baseline_y -= size * 1.2
end
```

This is verbose and error-prone (leading calculation, y overflow). A
multi-line helper centralizes the logic.

## Proposed API

```ruby
# Draw multiple lines of text with consistent leading.
# @param lines [Array<String>] text strings, one per line.
# @param font [Symbol] font resource name.
# @param size [Float] font size in points.
# @param leading [Float] line spacing in points (default: size * 1.2).
# @param at [Array(Numeric, Numeric)] [x, y] of the first line's baseline.
# @param char_spacing [Float, nil] optional character spacing.
# @param word_spacing [Float, nil] optional word spacing.
def text_lines(lines, font:, size:, at:, leading: nil,
               char_spacing: nil, word_spacing: nil)
  lead = leading || size * 1.2
  x, y = at
  lines.each do |line|
    text(line, at: [x, y], font: font, size: size,
         char_spacing: char_spacing, word_spacing: word_spacing)
    y -= lead
  end
  self
end
```

## Usage example

```ruby
# Simple multi-line text
canvas.text_lines(
  ["Line 1", "Line 2", "Line 3"],
  font: :F1, size: 12, at: [72, 720]
)

# Custom leading
canvas.text_lines(
  wrapped_text_array,
  font: :F1, size: 10, at: [72, 700], leading: 14
)
```

## Implementation notes

- Each line is a separate `text` call (no TJ array optimization).
  This is intentional: different lines may have different widths
  (justified vs left-aligned).
- The caller controls wrapping (via their own line breaker). This
  method only handles vertical positioning.
- `leading` follows PDF convention: distance between baselines.

## Priority

Low — the current approach (N `text` calls) works. But the helper
reduces boilerplate in every text-heavy rendering pipeline.
