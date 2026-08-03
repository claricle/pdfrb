# PROPOSAL: Missing `require "stringio"` in Fonts

## Summary

`Pdfrb::Document::Fonts` references `StringIO` without requiring it.
When pdfrb is loaded without another gem that happens to require
`stringio` first, `Fonts#register_font` raises `NameError`.

## Bug description

In `fonts.rb`, line 204:

```ruby
def register_font(resource, name, name_or_io, **opts)
  font_dict = if name_or_io.is_a?(IO) || name_or_io.is_a?(StringIO)
    #                                  ^^^^^^^^ NameError if stringio not loaded
```

Line 207 also uses `StringIO`:

```ruby
io = StringIO.new(File.binread(name_or_io))
```

There is no `require "stringio"` at the top of `fonts.rb`.

## Reproduction

```ruby
# In a clean Ruby process where stringio hasn't been loaded:
require "pdfrb"
doc = Pdfrb::Document.new
doc.fonts.add("/path/to/font.ttf")
# NameError: uninitialized constant Pdfrb::Document::Fonts::StringIO
```

In practice, other gems often load `stringio` first, masking this bug.
But it surfaces in minimal environments.

## Proposed fix

Add to the top of `lib/pdfrb/document/fonts.rb`:

```ruby
require "stringio"
```

Or add it to `lib/pdfrb.rb` (the main entry point).

## Priority

Low — easy one-line fix, but rare in practice (other gems usually
load stringio first).
