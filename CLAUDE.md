# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`pdfrb` is a pure-Ruby PDF library: a byte-level reader, an Arlington-model-driven typed domain model, and a serializer. The PDF object model is sourced **directly** from the vendored Arlington PDF Model TSVs (the machine-readable definition of ISO 32000-2:2020), so field metadata, version predicates, and validators stay aligned with the spec by *data*, not by hand-coded mimicry.

Two-direction contract:
- *"PDF file <=> Model"* — parse PDF bytes into a typed Model and serialize a Model back to PDF bytes. Round-trip is the correctness backbone.
- *"API Builder Input => Model"* — `Document`, `Canvas` build a typed Model from user intent; the serializer then writes it. (Layout concerns live in the sibling `arroolio` gem.)

Mirrors the layered design of the sibling `postscript` gem (PS/EPS). Architectural blueprint cross-referenced against HexaPDF.

## Commands

```sh
bundle install                      # first-time setup
bundle exec rake                    # default task: spec + rubocop
bundle exec rspec                   # all specs
bundle exec rspec spec/pdfrb/error_spec.rb:42   # one spec by line number
bundle exec rubocop                 # lint
bundle exec rubocop -A              # lint + safe autocorrect
bundle exec rake arlington:refresh  # re-vendor TSVs from ~/src/pdfa/arlington-pdf-model/tsv/
```

Run `bin/console` (create it if missing) for an interactive prompt preloaded with `Pdfrb`.

## Architecture (big picture)

| Layer | Owns | File |
|---|---|---|
| `Pdfrb::Source` | PDF bytes → tokens → COS object graph (read direction) | `lib/pdfrb/source.rb` |
| `Pdfrb::Model` | Typed PDF domain model: COS scalars + `Type::*` semantics | `lib/pdfrb/model.rb` |
| `Pdfrb::Arlington` | Loads vendored TSVs; evaluates `fn:` predicates. **Drives `Model` field definitions.** | `lib/pdfrb/arlington.rb` |
| `Pdfrb::Filter` | Stream filter pipeline (FlateDecode, LZWDecode, ...) | `lib/pdfrb/filter.rb` |
| `Pdfrb::Content` | Content-stream operators + Canvas drawing API | `lib/pdfrb/content.rb` |
| `Pdfrb::Serializer` | Model → PDF bytes (COS values) | `lib/pdfrb/serializer.rb` |
| `Pdfrb::Writer` | Document → file (xref + trailer assembly) | `lib/pdfrb/writer.rb` |
| `Pdfrb::Document` | Top-level facade | `lib/pdfrb/document.rb` |

### Layering rule (MECE)

Reader and Writer both depend on `Model` only. `Model` depends on `Arlington` for field metadata. `Content` extends `Model` with canvas + operators. Never shortcut across layers — the Serializer must never read bytes; the Parser must never write them.

### Autoload rule

Internal code uses **only** `autoload`, declared in the **immediate parent namespace's file**. Never `require_relative`, never `require "pdfrb/..."` for code in this gem (only `require` stdlib + gem deps). Create a namespace's file before adding children under it.

```ruby
# lib/pdfrb.rb
module Pdfrb
  autoload :Source, "pdfrb/source"     # lib/pdfrb/source.rb exists and holds Source's children autoloads
  autoload :Model, "pdfrb/model"       # lib/pdfrb/model.rb exists and holds Model's children autoloads
  ...
end
```

### Arlington integration

Each `Pdfrb::Model::Type::*` class declares `arlington_object "Catalog"` (or the matching TSV name). Calling it materializes `Field` objects from the vendored TSV in `data/pdfrb/arlington/latest/` and wires them into the dictionary's field set. Validation invokes predicate evaluators (`fn:IsRequired(...)`, `fn:SinceVersion(...)`, etc.).

**Never hand-edit field metadata on a `Model::Type::*` class.** The TSVs are the single source of truth. If a field is wrong, fix the TSV upstream and re-run `rake arlington:refresh`.

## Conventions (project-specific)

- `# frozen_string_literal: true` on **every** `.rb`.
- Immutable value objects. `freeze` in constructors where data crosses a layer boundary (mirrors `postscript`).
- Errors: every failure mode subclasses `Pdfrb::Error` and carries typed metadata (`source_position`, `filter_name`, `oid`/`gen`, `field_name`, etc.). See `lib/pdfrb/error.rb`.
- Specs: real instances, never `double()`. Use `Struct.new` for plain-data stand-ins. Property specs (`spec/pdfrb/round_trip_spec.rb`) are the correctness backbone.
- Forbidden Ruby patterns (per global memory):
  - `send` to private methods
  - `instance_variable_set` / `instance_variable_get`
  - `respond_to?` for type checks — use `is_a?`
  - hand-rolled `to_h`/`from_h`/`to_json`/etc. on model classes — declare fields, let the framework serialize
- Semantic types live under `Pdfrb::Model::Type::*` and are named after the matching Arlington TSV (e.g. `Catalog` ↔ `Catalog.tsv`).
- Content operators follow the registry pattern: one subclass per operator, `register_as` at the bottom of the file (mirrors `postscript`'s `Model::Operators`).
- Filters follow the same registry pattern: one subclass per filter, registered in `Pdfrb::Filter::REGISTRY`.
- Tests live under `spec/pdfrb/` mirroring the `lib/pdfrb/` structure. One spec file per source file.

## Where to look first

Before touching anything, read these five files in order:

1. `lib/pdfrb.rb` — autoload tree, the public surface.
2. `lib/pdfrb/error.rb` — failure taxonomy.
3. `lib/pdfrb/source.rb` — reading layer entry point.
4. `lib/pdfrb/model.rb` — domain model entry point.
5. `lib/pdfrb/arlington.rb` — model-driven-ness engine.

Then read the matching TODO entry in `TODO.general-rels/` for the feature you're working on.

## Reference repositories

These repos live outside the project tree but are the authoritative references. Paths assume the user's standard layout (`~/src/`).

| Path | Role |
|---|---|
| `~/src/claricle/postscript/` | Sibling gem to mimic — autoload pattern, layered Source/Model/Serializer, error hierarchy, rspec/rubocop setup. |
| `~/src/pdfa/arlington-pdf-model/` | Canonical PDF object model: ~600 TSV files (one per PDF object type) + `fn:` predicate grammar. **This is the data we port.** Refresh via `rake arlington:refresh`. |
| `~/src/external/hexapdf/` | Reference Ruby implementation. Architectural blueprint for Tokenizer/Parser/Dictionary/Type::*/Writer/Content/Canvas, security handlers, layout. We differ by sourcing field metadata from Arlington rather than hand-coding it. |
| `~/src/pdfa/spec-pdf-core/` | AsciiDoc source of ISO 32000-2 itself — text-of-truth for human reference, not a test corpus. |
| `~/src/pdfa/appnote-pdf20-002-af/` | PDF 2.0 Application Note 002 — Associated Files (`AF` key semantics, when `AF` is required, `EmbeddedFile` relationship). |
| `~/src/pdfa/appnote-pdf20-003-metadata/` | PDF 2.0 Application Note 003 — locations for object metadata streams (`Metadata` key placement; DPM stream exclusion). |
| `~/src/pdfa/technote-pdfua1-001/` | PDF/UA-1 Technical Note 001 — `ActualText` on `Figure` structure elements. |
| `~/src/pdfa/technote-pdfua1-002/` | PDF/UA-1 Technical Note 002 — `Reference` structure elements containing links. |

## Status

Released on RubyGems (0.7.x, BSD-2-Clause). The full stack is
implemented: reader/writer round-trip, content streams + Canvas,
encryption (RC4/AES-256), signatures, layout/Composer, conformance
validation (PDF/A, PDF/UA, PDF/X, PDF/VT), and the CLI.

**Arlington TSV coverage is complete** — 612 of 614 non-alias TSVs
map to `Model::Type::*` classes (only the two single-row OPI alias
wrappers remain, deliberately). Every commit goes through
PR + CI; the CHANGELOG records each release.

Known depth gaps: CFF/OTF font subsetting (only TrueType subsets),
veraPDF cross-check for PDF/A output. The original plan files live
in `TODO.general-rels/` (~157 entries, mostly landed).

`docs/USAGE.md` is the verified cookbook — `spec/pdfrb/usage_doc_spec.rb`
executes every snippet, so keep both in sync when changing public
APIs.
