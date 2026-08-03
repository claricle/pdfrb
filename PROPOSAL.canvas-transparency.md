# PROPOSAL: Canvas transparency and blend modes

## Summary

Add `Canvas#opacity=`, `Canvas#blend_mode=`, and
`Canvas#with_transparency(opacity:, blend_mode:, &block)` for
rendering semi-transparent page items with blending modes
(Multiply, Screen, Overlay, etc.).

## Motivation

The `idml` gem's element models include transparency attributes
(`BlendingSetting`, `OpacityGradientStop`, `FillTransparencySetting`)
that carry Opacity, BlendMode, and IsolatedKnockout settings. Without
transparency support in pdfrb's Canvas, these attributes are silently
ignored — semi-transparent shapes render at full opacity.

IDML documents commonly use:
- Semi-transparent overlays (Opacity = 50%)
- Multiply blend mode for shadow effects
- Screen blend mode for highlights
- Isolated blending groups

## Proposed API

```ruby
class Pdfrb::Content::Canvas
  # Set fill/stroke opacity (0.0–1.0).
  # Uses ExtGState with /ca (fill alpha) and /CA (stroke alpha).
  # @param alpha [Float] opacity value (0.0 = transparent, 1.0 = opaque).
  def opacity=(alpha)
    gs = document.ext_g_states.add(ca: alpha, CA: alpha)
    emit_op Operator::ApplyExtGState, gs
  end

  # Set blend mode for subsequent drawing operations.
  # @param mode [Symbol] one of: :Normal, :Multiply, :Screen,
  #   :Overlay, :Darken, :Lighten, :ColorDodge, :ColorBurn,
  #   :HardLight, :SoftLight, :Difference, :Exclusion,
  #   :Hue, :Saturation, :Color, :Luminosity.
  def blend_mode=(mode)
    gs = document.ext_g_states.add(BM: mode.to_s)
    emit_op Operator::ApplyExtGState, gs
  end

  # Execute a block with transparency settings, then restore.
  def with_transparency(opacity: 1.0, blend_mode: nil)
    save_graphics_state
    self.opacity = opacity if opacity < 1.0
    self.blend_mode = blend_mode if blend_mode
    yield self
    restore_graphics_state
  end
end
```

## PDF structure

Transparency requires an `/ExtGState` (Extended Graphics State)
dictionary with alpha and blend mode entries:

```
/ExtGState <<
  /Type /ExtGState
  /ca 0.5      % fill alpha
  /CA 0.5      % stroke alpha
  /BM /Multiply
  /SMask <<    % soft mask (optional)
    /Type /Mask /S /Alpha /G <form xobject>
  >>
>>
```

The Canvas applies it via `gs` operator:
```
/GS1 gs
```

## Document-level support

```ruby
class Pdfrb::Document
  class ExtGStates
    def add(ca: nil, CA: nil, BM: nil, SMask: nil)
      # Create ExtGState dict, register in /Resources/ExtGState
      # Return resource name (e.g., :GS1)
    end
  end
end
```

## Usage example

```ruby
# Semi-transparent red rectangle with multiply blend
canvas.with_transparency(opacity: 0.5, blend_mode: :Multiply) do
  canvas.fill_color([:rgb, 1, 0, 0])
  canvas.rectangle(100, 100, 200, 200)
  canvas.fill
end
```

## Priority

Low — transparency is an advanced feature. Most IDML documents don't
use it. But for documents that do, it's a visible rendering gap.
