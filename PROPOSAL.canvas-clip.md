# PROPOSAL: Canvas clip operators

## Summary

Add `Canvas#clip` and `Canvas#clip_path` methods for PDF clipping path
operators (`W`, `W*`, `n`), enabling content to be clipped to arbitrary
paths.

## Motivation

The IDML→PDF rendering pipeline (the `idml` gem) needs to clip placed
images to their parent Rectangle's bounds. Currently, pdfrb 0.3.0 has
no clip operator on Canvas. The `idml` gem implements a workaround via
`PdfrbExt::Clip` (custom `Operator::Base` subclass), but this belongs
in pdfrb itself.

Other use cases:
- Clipping text frames to their bounds
- Masking layers
- Cropping form XObjects
- Print marks (crop/bleed/trim)

## Proposed API

```ruby
# Set clipping path using nonzero winding rule.
# Must be called after defining a path (rectangle, move_to/line_to, etc.)
# and before drawing content that should be clipped.
# The clip persists until the graphics state is restored (Q).
def clip
  emit_op(Operator::ClipNonZero)
  emit_op(Operator::EndPath)
  self
end

# Set clipping path using even-odd rule.
def clip_even_odd
  emit_op(Operator::ClipEvenOdd)
  emit_op(Operator::EndPath)
  self
end
```

## Operator classes to add

```ruby
module Pdfrb::Content::Operator
  # PDF `W` — modify clipping path (nonzero winding)
  class ClipNonZero < NoArg
    def self.name; "W"; end
    register
  end

  # PDF `W*` — modify clipping path (even-odd)
  class ClipEvenOdd < NoArg
    def self.name; "W*"; end
    register
  end

  # PDF `n` — end path without filling or stroking
  class EndPath < NoArg
    def self.name; "n"; end
    register
  end
end
```

## Usage example

```ruby
canvas.save_graphics_state do
  canvas.rectangle(100, 100, 200, 200)
  canvas.clip  # clip to the rectangle
  canvas.draw_image(:Im1, at: [50, 50], width: 300, height: 300)
end
```

## Implementation notes

- `W` and `W*` are technically not no-arg operators in the strict PDF
  sense — they are modifiers applied to the current path. But since they
  take no operands, `NoArg` is the correct base class.
- `n` is already listed as `EndPath` in the operator module but may not
  be registered. If it is, `Canvas#end_path` already exists and can be
  reused.
- The `clip` method should call `end_path` after `W`/`W*` to consume
  the path, matching the common `W n` idiom.

## Priority

Medium — commonly needed for any PDF rendering pipeline that places
images or text within geometric frames.
