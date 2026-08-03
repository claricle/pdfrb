# PROPOSAL: Canvas rich text — multi-run text in one BT/ET block

## Summary

Add `Canvas#text_rich(runs, at:)` for drawing text with per-run font,
size, color, and positioning. Eliminates the need for N separate
`text` calls when a paragraph contains mixed styling (e.g., bold word
within regular text, different font sizes, color changes).

## Motivation

The `idml` gem's `TextFrameRenderer` renders styled text from IDML
documents where a single paragraph can contain multiple
`CharacterStyleRange` runs — each with its own font, size, and color.
Currently, each run requires a separate `canvas.text` call (separate
BT/ET block), which:

1. Produces a larger content stream (more BT/ET pairs).
2. Loses cursor continuity — the caller must compute the x-offset
   after each run manually.
3. Can't use `TJ` (array show) for kerning between runs.

## Proposed API

```ruby
# Draw multiple text runs in a single BT/ET block with cursor
# tracking. Each run advances the text cursor by its width.
#
# @param runs [Array<Hash>] each hash has:
#   :text [String] the text to show.
#   :font [Symbol] font resource name.
#   :size [Float] font size in points.
#   :color [Array, nil] optional fill color (e.g., [:rgb, 1, 0, 0]).
#   :char_spacing [Float, nil] optional character spacing.
# @param at [Array(Numeric, Numeric)] [x, y] of the first run's baseline.
#
# Example:
#   canvas.text_rich([
#     { text: "Hello ", font: :F1, size: 12 },
#     { text: "World", font: :F1, size: 12, color: [:rgb, 1, 0, 0] },
#     { text: "!", font: :F1, size: 14 },
#   ], at: [72, 720])
def text_rich(runs, at:)
  emit_op Operator::BeginText
  cursor_x, cursor_y = at

  runs.each do |run|
    emit_op Operator::Font, run[:font], run[:size]
    emit_op Operator::SetTextMatrix, 1, 0, 0, 1, cursor_x, cursor_y
    if run[:color]
      fill_color(run[:color])
    end
    encoded = document.fonts.encode_text(run[:text], run[:font])
    width = document.fonts.measure_text(run[:text],
                                        font: run[:font],
                                        size: run[:size])
    emit_op Operator::ShowText, escape_pdf_string(encoded)
    cursor_x += width
  end

  emit_op Operator::EndText
  self
end
```

## Alternative: TJ (array show) optimization

For runs with the same font and size, use `TJ` to show text with
positioning adjustments in a single operator:

```
[(Hel) -50 (lo W) 20 (orld!)] TJ
```

This enables kerning between runs and reduces operator count. But it
requires all runs to use the same font/size, which limits its use.

## Implementation notes

- `text_rich` uses `SetFont` (Tf) per run to switch fonts within the
  same BT/ET block. This is valid PDF — Tf can be called multiple times.
- Color changes use `SetFillColor` (rg/k) between runs.
- `SetTextMatrix` (Tm) positions each run at the absolute cursor.
- The cursor advances by `measure_text(run[:text], ...)` after each run.

## Usage example

```ruby
# Render a paragraph with mixed styling
canvas.text_rich([
  { text: "This is ", font: :F1, size: 12 },
  { text: "bold", font: :F2, size: 12 },       # F2 = bold variant
  { text: " text in ", font: :F1, size: 12 },
  { text: "red", font: :F1, size: 12, color: [:rgb, 1, 0, 0] },
  { text: ".", font: :F1, size: 12 },
], at: [72, 720])
```

## Priority

Medium — the `idml` gem works around this with N `text` calls, but
`text_rich` would produce cleaner, smaller content streams and enable
proper kerning between styled runs.
