# Changelog

All notable changes to the pdfrb gem will be documented in this file.

## [0.1.1] — 2026-08-02

### Housekeeping

* **Layout/Composer extracted to sibling `arroolio` gem.** Pdfrb is now
  pure PDF: bytes ↔ model. No page templates, no flows, no Knuth-Plass,
  no tables, no SVG. Removed `lib/pdfrb/layout/`, `lib/pdfrb/composer.rb`,
  `lib/pdfrb/layout.rb`, `spec/pdfrb/layout/`, `TODO.layout/`.
* **Removed `rexml` runtime dependency** (was only needed for the FO
  parser, which moved to Arroolio).
* **Fixed all 12 rubocop offenses.** 0 offenses remaining. Disabled
  `RSpec/DescribeClass` (legitimate string describes in integration tests).
* **Added SimpleCov** (opt-in via `COVERAGE=1` env var). Current line
  coverage: **84.5%**. Grouped by Source / Model / Filters / Content /
  Font / Encryption / Tasks / CLI / Document.
* **Replaced 3 `pending` specs with `skip`** — clearer exit semantics
  for strict CI runs.
* **Fixed `Model::Cos::Stream#as_parms_list`** — Hash parms now
  correctly wraps to `[parms]` instead of `Array(parms)` which
  produced `[[:k, :v], ...]`. Bug was hidden by tests that didn't
  exercise DecodeParms as a Hash through the Stream facade.
* **Renamed CMap format dispatchers** — `parse_format_4` →
  `parse_format_four`, etc. (rubocop `Naming/VariableNumber`).
* **README/CLAUDE.md** updated to reflect pure-PDF scope; layout
  concerns documented as living in `arroolio`.

### Verified

* 503 examples, 0 failures, 3 pending (conformance specs awaiting
  fixture corpus).
* 0 rubocop offenses.
* `gem build pdfrb.gemspec` produces `pdfrb-0.1.1.gem`.
* End-to-end round-trip: build PDF → write → read → extract text →
  matches.

## [0.1.0] — 2026-08-02

### Initial release

Pure-Ruby PDF library: byte-level reader, Arlington-model-driven typed
domain model, and serializer.

* Source: bytes → tokens → COS graph.
* Model: typed COS values + Type::* semantics, sourced from vendored
  Arlington PDF Model TSVs (ISO 32000-2:2020).
* Filter pipeline: FlateDecode, ASCII-Hex, ASCII-85, LZW, RunLength,
  CCITTFax, DCT, JPX, JBIG2, Crypt.
* Content: 52 content-stream operators + Canvas drawing API.
* Encryption: RC4 (pure Ruby), AES (OpenSSL), StandardSecurityHandler
  (V1-V6 / R2-R6).
* Font machinery: AFM parser, 5 encoding tables, CMap parser, TrueType
  file parser (head/hhea/hmtx/cmap/OS-2), Type1 metrics.
* Image loaders: JPEG, PNG, PDF page import.
* Tasks: ExtractText (with /ToUnicode CMap), ExtractImages, Merge,
  Optimize.
* CLI: version, info, tree, merge, extract-text/images, encrypt,
  decrypt, optimize, form.
* Conformance: PDF/A + PDF/UA rule subsets.
* Round-trip property tested against ISO 32000-2 Annex H examples
  (12 PDFs).

## [Unreleased]

### Added — 2026-08-01 (layout engine session)

**Full layout engine + XSL-FO pipeline (TODO.layout 01–17).**

* `Pdfrb::Layout::FontMetrics` (AfmMetrics + TrueTypeMetrics) +
  `GlyphMeasurer` — real glyph widths for the 14 standard Type1 fonts
  (via Adobe AFM, now vendored) and any TTF/OTF (via head/hhea/hmtx/
  cmap/OS-2 table parsers). Replaces the 0.5×font_size estimate; matches
  Adobe metrics to 0.01pt.
* `Pdfrb::Layout::TextLayout` — Greedy and Knuth-Plass line breaking
  with real glyph metrics, alignment (left/right/center/justify),
  hyphenation hooks, and break-opportunity finder that handles
  multi-run paragraphs (bold spans, hyperlinks).
* `Pdfrb::Layout::PageFlow` + `Flowable` + `Frame` — flowing-text
  engine with split-on-page-break for paragraphs/tables, keep-together,
  page-break-before/after, and a two-pass static-content render for
  `fo:page-number` and `fo:page-number-citation`.
* `Pdfrb::Layout::Table` + `TableLayout::Fixed` + `TableLayout::Auto`
  + `TableFlowable` + `TableRenderer` — fixed-width and CSS 2.1
  auto-width column layout, row/col spans, header row repeat across
  page breaks.
* `Pdfrb::Layout::PageTemplate` + `Region` + `PageSequenceMaster` +
  `StaticContent` — page geometry with 5 regions (body/before/after/
  start/end) and odd/even/first/last/blank page-template selection.
* `Pdfrb::Layout::Leader` + `FieldRun`s (PageNumberField,
  PageNumberCitationField, PageCountField) — TOC leaders and
  page-number fields, resolved via the two-pass layout.
* `Pdfrb::Layout::SVG::*` — SVG → PDF renderer supporting path data,
  rect/circle/ellipse/line/polyline/polygon, text, image (with
  data: URI), nested groups with transforms, and presentational
  styling. New SVG element = one Element subclass.
* `Pdfrb::Layout::FO::*` — XSL-FO parser (REXML-based) + PropertyResolver
  (inheritance + shorthand expansion) + MasterBuilder + FlowBuilder +
  Compiler. End-to-end: `Pdfrb.render_fo(xml, io:)` produces a PDF.
* `Pdfrb.parse_fo(xml)` and `Pdfrb.render_fo(xml, path_or_io:)` top-level
  entry points.

### Fixed — 2026-08-01 (layout engine session)

* `Pdfrb::Font::AFMParser` — handle `StartCharMetrics 315` (with count),
  not just bare `StartCharMetrics`.
* `Pdfrb::Font::GlyphList` — accept both canonical hex format and
  literal-Unicode repackagings of glyphlist.txt.
* `Pdfrb::Filter::FlateDecode` — `out << unfiltered.pack("C*")` so PNG
  predictor output is concatenated correctly (was appending Array to
  String).
* `Pdfrb::Model::Cos::Stream#decoded_stream` — use type-checked
  `as_filter_list` / `as_parms_list` helpers instead of `Array(...)`,
  which silently converts a Hash `DecodeParms` to `[[:k, :v], ...]`
  and bypasses the predictor.
* `Pdfrb::Source::ObjectReader#load_from_objstm` — unpack the
  `[oid, value]` pair from ObjectStreamReader and re-wrap via
  `document.wrap` so type-dispatch (Catalog, Pages, etc.) works for
  compressed objects.
* `Pdfrb::Document::Pages#count` — dereference Reference-typed `/Count`
  before treating as Integer; fall back to walking the Kids tree.
* `Pdfrb::Document::Pages#walk` — robust against Reference-typed
  `/Kids` arrays (common in FOP output).

### Added — 2026-07-30 (session 2)

**Phase 2 — COS layer (TODOs 08–14).**

* `Pdfrb::Model::Object` — base wrapper with `value`, `oid`, `gen`,
  `document`; `indirect?`, `must_be_indirect?`, `deref`, `pdf_type`.
* `Pdfrb::Model::Reference` — frozen value object by `(oid, gen)`,
  hashable, comparable, serialises as `"5 0 R"`.
* `Pdfrb::Model::PdfArray < Object` — Enumerable wrapper around an
  Array of PDF values, with full mutation API and oid/gen/document
  support for indirect arrays.
* `Pdfrb::Model::Rectangle` — immutable `[llx lly urx ury]` value
  with `width`, `height`, `left`/`right`/`top`/`bottom`.
* `Pdfrb::Model::Matrix` — immutable `[a b c d e f]` affine with the
  PDF-correct column-vector composition (`M1 * M2` applies M2 then
  M1) and translate/scale/rotate/skew factories.
* `Pdfrb::Model::Date` — PDF date `D:YYYYMMDDHHmmSSOHH'mm'` <-> `Time`.
* `Pdfrb::Model::Cos::NameEncoding` — Symbol <-> `/...` wire format
  with `#xx` escape encode/decode.
* `Pdfrb::Model::Cos::StringEncoding` — text/binary string helpers:
  UTF-16BE BOM detection, full PDFDocEncoding table (Appendix D.2),
  PDFDocEncoding <-> UTF-8 conversion.
* `Pdfrb::Model::Cos::Fields::Field` — typed field metadata with
  `resolved_types`, `valid_value?`, Arlington slot.
* `Pdfrb::Model::Cos::Fields` converters: Dictionary, Array, String,
  PDFByteString, Date, Rectangle, Integer — selected by `usable_for?`
  and applied in order via `Fields.apply`.
* `Pdfrb::Model::Cos::Dictionary` — base class with `define_field`,
  `field`, `each_field`, type registry (`register_type`/`lookup_type`),
  `[]`/`[]=` with full pipeline (default -> dereference -> unbox ->
  convert), `each`/`each_raw`, `validate`.
* `Pdfrb::Model::Cos::Stream < Dictionary` — raw-bytes holder with
  `decoded_stream` / `encoded_stream=` that drives `Pdfrb::Filter`.
* `Pdfrb::Document` — top-level facade with `wrap`, `add`,
  `object`/`dereference`, `register_listener`/`dispatch_message`.

**Phase 5 partial — Filters (TODOs 34–36).**

* `Pdfrb::Filter` module + registry; `Filter.apply(bytes, filters:,
  parms:, direction:, document:)` chains decoders/encoders.
* `Pdfrb::Filter::Base` — included interface; subclasses call
  `register_as "Name"`.
* `Pdfrb::Filter::FlateDecode` — zlib + PNG predictor unfiltering
  (None/Sub/Up/Average/Paeth).
* `Pdfrb::Filter::ASCIIHexDecode` — hex <-> bytes with EOD marker `>`.

**Phase 6 — Arlington layer (TODOs 45–53).**

* Vendored `data/pdfrb/arlington/latest/*.tsv` — 613 TSV files from
  `~/src/pdfa/arlington-pdf-model/tsv/latest/`. Single source of
  truth for PDF object model.
* `Pdfrb::Arlington::Loader` — lazy TSV reader with `(name, version)`
  memoisation. `object_definition("Catalog")` returns a parsed
  `ObjectDefinition`.
* `Pdfrb::Arlington::ObjectDefinition` / `FieldDefinition` — typed
  records for one TSV / one row. FieldDefinition exposes bare types,
  required/predicate-split required, links, possible-value lists.
* `Pdfrb::Arlington::Type` — the 17 type symbols + validity check.
* `Pdfrb::Arlington::PdfVersion` — Comparable value object with full
  `.from_tsv_cell` parsing (plain, `fn:Extension(name, ver)`, `fn:Eval`).
* `Pdfrb::Arlington::Predicate::Lexer/Parser/AST/Evaluator/Context`
  — full `fn:` mini-DSL: tokeniser, recursive-descent parser
  (logical ops require parens per spec), evaluator with `@key`,
  `parent::`, `trailer::` path resolution, and BinOp/UnaryOp/LogicalOp
  evaluation.
* `Pdfrb::Arlington::Predicate::Functions` registry + 6 built-in
  groups (OCP: one file per category):
  - `version.rb` — SinceVersion, BeforeVersion, Deprecated,
    IsPDFVersion, Extension.
  - `presence.rb` — IsRequired, IsPresent, NotPresent.
  - `logical.rb` — Eval, Not, And, Or.
  - `arithmetic.rb` — ArrayLength, StringLength, RequiredValue,
    BitSet, BitsClear, BitsSet, KeyNameIsColorant, NoCycle.
  - `reference.rb` — MustBeDirect, MustBeIndirect.
  - `file.rb` — FileSize.
* `Dictionary.arlington_object "Name"` — pulls field metadata from
  the matching TSV at class-load time and feeds it through
  `define_field`. Type mapping from the 17 Arlington symbols to Ruby
  classes (booleans -> [TrueClass, FalseClass], name -> Symbol,
  rectangle -> Rectangle, etc.).

**Phase 15 partial — fixture corpus sourcing (TODOs 148, 158).**

* `claricle/pdf-core-examples` forked from
  `pdf-association/pdf-core-examples` (private). The `ci` team is on
  both `claricle/pdfrb` and `claricle/pdf-core-examples`, so
  `claricle-ci` (already on `ci`) can pull examples in CI using
  `CLARICLE_CI_PAT_TOKEN`.
* TODO 148 updated: corpus is fetched (not committed) via
  `rake fixtures:pull`; `spec/fixtures/pdf-core-examples/` is
  gitignored.
* TODO 158 added: GitHub Actions workflow that pulls the corpus
  before rspec.

### Stats

* 163 specs, 0 failures, 0 rubocop offenses.
* 39 source files under `lib/`, 12 spec files under `spec/`.
* 613 vendored TSVs under `data/pdfrb/arlington/latest/`.
* 158 TODO files in `TODO.general-rels/` (added 158 for CI).

### Code quality

* Pure Ruby `autoload` everywhere; no `require_relative` in lib/.
* No `respond_to?` for type checks, no `instance_variable_set/get`,
  no `send` to private methods.
* `# frozen_string_literal: true` on every `.rb`.
* Real instances in specs, never `double()`.

---

### Added — 2026-07-30

**0.1.0 — initial scaffold.**

The pdfrb gem is created as a pure-Ruby PDF library modelled on the
sibling `postscript` gem and HexaPDF, with the PDF object model driven
directly by the vendored Arlington PDF Model TSVs.

* Project skeleton: gemspec, Gemfile, Rakefile (default = spec +
  rubocop), `.rspec`, `.rubocop.yml` (Cimas base + rspec/performance/
  rake plugins), `.gitignore`, `.gitattributes` (TSV EOL=LF).
* `Pdfrb::PdfConstants` — PDF lexical constants (header magic, EOL,
  whitespace, delimiters, version enumeration, keywords) per
  ISO 32000-2:2020 s7.2.
* `Pdfrb::Error` hierarchy — typed errors for every failure mode:
  `ParseError` (with `source_position`), `LexError`, `SyntaxError`,
  `MalformedPdfError` (with `recovered?`), `SerializeError`,
  `FilterError` (with `filter_name`), `EncryptionError`,
  `UnsupportedVersionError`, `ObjectReferenceError` (with oid/gen),
  `ValidationError` (with field/predicate names).
* `Pdfrb::Configuration` — per-Document frozen settings hash with
  deep-merge. Defaults for malformed-PDF recovery, auto-decrypt,
  invalid-string handling.
* `Pdfrb::DataDir` — resolves paths under the gem's bundled
  `data/pdfrb/` (Arlington TSVs, AFM, ICC, etc.).
* Top-level `lib/pdfrb.rb` autoload tree for all planned namespaces
  (Source, Model, Arlington, Filter, Content, Encryption,
  DigitalSignature, Font, FontLoader, ImageLoader, Layout, Task,
  Serializer, Writer, Importer, Revision(s), XrefSection, Document,
  Composer, CLI). Lazy: file not loaded until constant accessed.
* `Rakefile` `arlington:refresh` task to re-vendor TSVs from
  `~/src/pdfa/arlington-pdf-model/tsv/latest/`.
* `CLAUDE.md` onboarding doc.
* `TODO.general-rels/` work-breakdown structure (157 entries across
  16 phases).

### Architecture

Mirrors `postscript`'s layered split (Source / Model / Serializer)
extended for PDF's needs. The differentiator vs HexaPDF is that
field metadata is loaded at runtime from the vendored Arlington TSVs
(single source of truth) rather than hand-coded via `define_field`.

### Code quality

* Pure Ruby `autoload` everywhere; no `require_relative` in lib/.
* No `respond_to?` for type checks, no `instance_variable_set/get`,
  no `send` to private methods.
* `# frozen_string_literal: true` on every `.rb`.
* Real instances in specs, never `double()`.
