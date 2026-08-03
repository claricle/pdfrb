# PROPOSAL: Canvas draw_image with transform matrix

## Summary

Add `Canvas#draw_image_matrix(name, a:, b:, c:, d:, e:, f:)` for drawing
image XObjects with an arbitrary affine transform matrix, complementing
the existing `Canvas#draw_image(name, at:, width:, height:)` which only
supports position + uniform scale.

## Motivation

The `idml` gem places images using IDML's `ItemTransform` — a full 2D
affine matrix `a b c d e f` that includes non-uniform scaling, rotation,
and translation. The current `draw_image` only accepts `at: [x, y]` and
`width:, height:`, which can't express rotation or skew.

Currently the `idml` gem works around this by emitting raw operators:

```ruby
canvas.concat(scale_x, 0, 0, scale_y, x, y)
canvas.emit_op(PdfrbExt::InvokeXObject, name)
```

This works but bypasses pdfrb's Canvas abstraction. A proper API method
would be cleaner and more discoverable.

## Proposed API

```ruby
# Draw an image XObject with a full affine transform matrix.
# The matrix maps the image's unit square (0,0)-(1,1) to the
# destination rectangle on the page.
#
# @param name [Symbol] image resource name from Document#images#add.
# @param a, b, c, d, e, f [Numeric] affine matrix components.
#
# Example: scale 200×150 and place at (72, 300):
#   canvas.draw_image_matrix(:Im1, a: 200, b: 0, c: 0, d: 150, e: 72, f: 300)
#
# Example: rotate 45° and scale:
#   rad = 45 * Math::PI / 180
#   cos = Math.cos(rad)
#   sin = Math.sin(rad)
#   canvas.draw_image_matrix(:Im1, a: cos*200, b: sin*200, c: -sin*150, d: cos*150, e: 100, f: 400)
def draw_image_matrix(name, a:, b:, c:, d:, e:, f:)
  save_graphics_state do
    concat(a, b, c, d, e, f)
    emit_op(Operator::InvokeXObject, name)
  end
  self
end
```

## Alternative: extend draw_image

```ruby
def draw_image(name, at: nil, width: nil, height: nil, matrix: nil)
  if matrix
    a, b, c, d, e, f = matrix
    save_graphics_state { concat(a, b, c, d, e, f); emit_op(Operator::InvokeXObject, name) }
  else
    # existing at:/width:/height: behavior
  end
end
```

## Register InvokeXObject operator

This proposal also requires registering the `Do` (Invoke XObject)
operator in pdfrb's operator catalogue:

```ruby
module Pdfrb::Content::Operator
  class InvokeXObject < Base
    class << self
      def name; "Do"; end
      def serialize(serializer, name); "/#{name} Do\n"; end
    end
    register
  end
end
```

## Priority

Medium — the `idml` gem has a workaround via PdfrbExt, but pdfrb should
have the `Do` operator and a matrix-aware image drawing method built-in.
