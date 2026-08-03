# PROPOSAL: Page MediaBox setter

## Summary

Add `Page#media_box=` setter method so pages can have custom dimensions
without accessing the COS dictionary directly.

## Motivation

The `idml` gem renders IDML documents with arbitrary page sizes (A4,
business card, poster, etc.). pdfrb defaults to US Letter (612×792).
Currently, setting a custom MediaBox requires:

```ruby
page = document.pages.add
page[:"MediaBox"] = [0, 0, width, height]  # COS dict access
```

This is fragile — it bypasses pdfrb's model layer and couples the caller
to COS internals. A proper setter provides a clean, model-driven API.

## Proposed API

```ruby
class Pdfrb::Model::Type::Page
  # Set the page's MediaBox.
  # @param box [Array<Numeric>] [llx, lly, urx, ury] in PDF points.
  def media_box=(box)
    self[:"MediaBox"] = box
  end
end
```

Alternatively, support it at creation time:

```ruby
# In Pages#add
def add(width: 612, height: 792, **opts)
  page = super(**opts)
  page.media_box = [0, 0, width, height] unless width == 612 && height == 792
  page
end
```

## Usage example

```ruby
# A4 portrait
page = document.pages.add
page.media_box = [0, 0, 595, 842]

# Custom size via creation
page = document.pages.add(width: 595, height: 842)
```

## Implementation notes

- The reader method `media_box` already exists.
- The setter is a one-liner delegating to `self[:"MediaBox"]=`.
- The COS dict `[]=` is public (inherited from Cos::Dictionary).
- No validation needed at this level — callers pass valid rectangles.

## Priority

Low — workaround exists via `page[:"MediaBox"] = [...]`. But a proper
setter improves API cleanliness and discoverability.
