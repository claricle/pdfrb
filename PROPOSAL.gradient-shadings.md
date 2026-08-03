# PROPOSAL: Gradient shading patterns

## Summary

Add `Document#shadings` facade and `Canvas#fill_shading(name)` /
`Canvas#stroke_shading(name)` for PDF Type 2 (axial) and Type 3 (radial)
gradient shading patterns. Replaces the discrete-rectangle approximation
used by the `idml` gem.

## Motivation

The `idml` gem renders IDML gradient fills as 32 discrete colored
rectangles (a "staircase" approximation). This produces visible banding
and a larger file size than a proper PDF shading pattern.

PDF natively supports smooth gradients via shading dictionaries:
- **Type 2 (Axial)**: linear gradient between two points.
- **Type 3 (Radial)**: circular gradient between two circles.
- **Type 4–7 (Free-form, Coons, Tensor-product)**: complex meshes.

A proper shading pattern produces a mathematically smooth gradient with
zero banding.

## Proposed API

```ruby
module Pdfrb
  class Document
    class Shadings
      # Add an axial (linear) gradient.
      # @param from [Array(Numeric, Numeric)] start point [x, y].
      # @param to [Array(Numeric, Numeric)] end point [x, y].
      # @param stops [Array<Array>] gradient stops:
      #   [[offset, [color_family, *values]], ...]
      #   e.g., [[0.0, [:rgb, 1, 0, 0]], [1.0, [:rgb, 0, 0, 1]]]
      # @return [Symbol] shading resource name (e.g., :Sh1).
      def add_axial(from:, to:, stops:)
      end

      # Add a radial gradient.
      # @param from [Array(Numeric, Numeric, Numeric)] [cx, cy, radius].
      # @param to [Array(Numeric, Numeric, Numeric)] [cx, cy, radius].
      # @param stops [Array<Array>] same format as axial.
      # @return [Symbol] shading resource name.
      def add_radial(from:, to:, stops:)
      end

      def [](name); end
      def each(&block); end
    end
  end
end
```

```ruby
class Pdfrb::Content::Canvas
  # Fill the current path using a shading pattern.
  # @param name [Symbol] shading resource name from Shadings#add_axial.
  def fill_shading(name)
    emit_op(Operator::ShadingFill, name)
  end
end
```

## PDF structure

```
/Shading << /Sh1 << /Type /Shading /ShadingType 2
  /ColorSpace /DeviceRGB
  /Coords [x0 y0 x1 y1]
  /Function << /FunctionType 4 /Domain [0 1]
    /Range [0 1 0 1 0 1]
    /Length N >> stream { ... PostScript calculator ... } endstream
>> >>
```

For simple 2-stop gradients, a Type 2 ExponentialInterpolation
function is simpler:

```
/Function << /FunctionType 2 /Domain [0 1]
  /C0 [1 0 0] /C1 [0 0 1] /N 1 >>
```

## Usage example

```ruby
shading = doc.shadings.add_axial(
  from: [0, 0], to: [200, 0],
  stops: [[0.0, [:rgb, 1, 0, 0]], [1.0, [:rgb, 0, 0, 1]]]
)
page.canvas.rectangle(0, 0, 200, 100)
page.canvas.fill_shading(shading)
```

## Implementation notes

- Shadings need to be in `/Resources/Shading` on each page (or in the
  catalog for document-wide).
- Multi-stop gradients require a StitchingFunction (Type 3) that
  chains multiple Type 2 interpolation functions.
- For color spaces, support DeviceRGB, DeviceCMYK, and DeviceGray.
- The `sh` operator (shading fill) ignores the current path — it fills
  the entire shading clip area. To clip to a shape, use the path as a
  clip before `sh`.

## Priority

Medium — gradients are a visual quality issue, not a correctness issue.
The discrete approximation works but produces visible banding.
