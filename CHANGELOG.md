# Changelog

All notable changes to the pdfrb gem will be documented in this file.

## [Unreleased]

### Added — Parity batches 4-9

* **TODO 103 Hyphenation** — Knuth-Liang `Pdfrb::Layout::Hyphenation`
  with curated English patterns in `data/pdfrb/layout/hyphenation_en.txt`.
* **TODO 116 PDF/X-6** — `Pdfrb::Conformance::PdfX#X6` ISO 15930-11
  profile.
* **TODO 117 PDF/VT** — `Pdfrb::Conformance::PdfVT` (VT-1, VT-2)
  ISO 16612-2 profiles.
* **TODO 118 Multi-revision traversal** — `Document#each_revision`
  walks the `/Prev` chain yielding `(revision_index, xref, trailer)`.
* **TODO 119 Table cell spans** — `TableBox.cell(box, colspan:,
  rowspan:)`, hash-form cells, span-aware layout.
* **TODO 120 Multi-page table** — `MultiPageTableBox` splits a table
  across pages with header-row repeat.
* **TODO 122 Bidi** — `Pdfrb::Layout::Bidi` paragraph-level UAX #9
  reordering; `TextLayouter` reorders Hebrew/Arabic for visual order.
* **TODO 128 Linearization-aware reader** —
  `Source::LinearizationReader.detect(io)` parses the first indirect
  object's dict for `/Linearized`.
* **TODO 129 Type3 font loader** — `Pdfrb::FontLoader::Type3` with
  glyph procedures + encoding.
* **TODO 131 Inline images (write)** — `Canvas#inline_image(dict:,
  data:)` plus `Operator::{BeginInlineImage, EndInlineImage}`.
* **TODO 133 Custom canvas primitives** — `polyline`, `polygon`,
  `arc`, `circle`, `ellipse`, `rounded_rectangle`, `dash=`.
* **TODO 135 PDF thumbnail generation** — `Pdfrb::Task::Thumbnail`
  builds `/Thumb` image XObjects on every page.
* **TODO 136 PDF/A preflight deep** — `PREFLIGHT_DEEP` rule set on
  PdfA (JavaScript, PostScript XObjects, encryption, embedded-file
  bans for A-1/A-2/A-4).
* **TODO 137 PDF/UA tagging deep** — list/LI/LBody, Table/TR,
  TH/Scope structural checks.
* **TODO 138 Tagged PDF validation** —
  `Pdfrb::Conformance::TaggedPdf` baseline structural rule set.
* **TODO 140 PDF 2.0 AF validation** —
  `Pdfrb::Conformance::Pdf2AF` App Note 002 validator.
* **TODO 104 Default ICC profile** — `Color::DefaultProfile` emits a
  usable sRGB v4 ICC profile with desc/wtpt/rXYZ/gXYZ/bXYZ/rTRC/
  gTRC/bTRC tags and a real MD5 Profile ID.
* **TODO 139 ICC profile validation** —
  `Pdfrb::Color::ICCValidator` checks signature, version, device
  class, color space per ICC.1:2022 §7.
* **TODO 108 Image downsampling** —
  `Pdfrb::Image::Downsampler` + `Task::Optimize#downsample_images!`
  for FlateDecode 8-bpc non-palette images.
* **TODO 130 Color-key masking** — `ImageLoader::PNG` parses tRNS and
  emits `/Mask` color-key array.
* **TODO 131 Inline images (read)** — `Content::Parser` recognises
  the BI/ID/EI sequence and yields an `InlineImage` invocation.
* **TODO 132 Page-piece dict** —
  `Pdfrb::Model::Type::PagePieceInfo` per s14.5.
* **TODO 134 Tagged PDF alt-text API** — `Document::Structure`
  facade for `/Alt`, `/ActualText`, `/Lang`.
* **Layout** — cluster-aware default `TextShaper`, real AFM-based
  `FontFallback`, `PolygonFrame` with proper inscribed-rectangle
  scan, `MultiCellTextLayout`, `JustificationKashidas`.
* **Encryption** — `StandardSecurityHandler.for_v5` write-side
  AES-256 R6 handler (file key + `/U`/`/O`/`/UE`/`/OE`/`/Perms`),
  `V5Writer` PKCS#5 algorithms, `PublicKeySecurityHandler` with
  real CMS EnvelopedData construction via `OpenSSL::PKCS7`.
* **Signatures** — `Pdfrb::Conformance::Pades` (B-B, B-T, B-LT,
  B-LTA profiles), `Pdfrb::Conformance::Ltv` long-term validation,
  `Pdfrb::Conformance::PdfA4Deep`, `PdfUA2Deep`,
  `DigitalSignature::TimestampClient` (RFC 3161 TSA over HTTPS).
* **Images** — `ImageLoader::TIFF` decodes uncompressed RGB/gray;
  `ImageLoader::GIF` does full GIF-spec LZW decode with palette.
* **Source** — extended `Pdfrb::Source::Recovery` with
  trailer-reference recovery, hybrid-xref detection,
  object-stream rebuild.
* **Tasks** — `Pdfrb::Task::RegenerateAppearances` walks widget
  annotations and rebuilds `/AP /N` via `Appearance::Generator`.

### Fixed

* Stream deduplication in `Task::Optimize` (was a stub).
* `Writer#write_xref_stream` now emits a free entry for every gap
  in the oid space (was misaligning the reader).
* `Document::Form#flatten!` now stamps field appearances into page
  content via `/Do` (was a stub).
* Issue #63: PostScript name extraction for `/BaseFont`.
* Issue #64: `Resources#empty?` handles Hash, Array, Cos::Dictionary,
  PdfArray.

### Changed

* Release workflow switched to emf2svg-ruby pattern: direct OIDC
  trusted publishing via `rubygems/configure-rubygems-credentials@main`
  + plain `gem push`. Bump job commits version.rb and tags `vX.Y.Z`.
* Removed all `instance_variable_set/get`, `send` to private
  methods, `respond_to?` for type checks.

## [0.7.39] — 2026-08-24

### Added

* `DestOutputProfile` dictionary — the TSV that
  `DestOutputProfileRef` (an indirect-reference model) points at.
  Completes Arlington TSV mapping: **612 of 614** non-alias TSVs
  covered.

## [0.7.38] — 2026-08-24

### Added

* Parity batch 36 — the final 31 TSVs: EncryptedPayload, Permissions,
  FDDict, StreamDict, DictionaryOf{Dictionaries,Functions},
  LinearizationParameterDict, FixedPrint, FloatingWindowParameters,
  FontFileType1, Mac, MicrosoftWindowsLaunchParam,
  MinimumBitDepth/MinimumScreenSize, NavNode, Navigator, PaperMetaData,
  SlideShow, Solidities, SourceInformation, SpectralData, ViewParams,
  DPMMetadataStream, Data; BeadFirst, ThreeDViewAddEntries,
  MovieActivation, AppearancePrinterMarkDict, OptContentUsage;
  mappings for CMapStream and ExDataProjection.

### Fixed

* Local/CI rubocop drift — lockfile now pins rubocop 1.90.0 (the
  `~> 1.75` constraint let CI install newer rubocop than local);
  converted single-statement disable/enable pairs to `disable-next`.

## [0.7.37] — 2026-08-24

### Added

* Parity batch 35 — 18 TSVs: CertSeedValue, SubjectDN, DocTimeStamp,
  TimeStampDict, AuthCode, LegalAttestation, VRIMap,
  SignatureBuildPropDict mapping; AFEmbeddedFileParameter/AFFileSpecEF
  (App Note 002); Target/TargetEmbedded (GoToE); DevExtensions family +
  Extensions container; GTS_ProcStepsGroup; AAPL_ST.

## [0.7.36] — 2026-08-24

### Added

* Parity batch 34 — 17 TSVs: geospatial family
  (Geographic/ProjectedCoordinateSystem, PointData, Projection,
  NumberFormat), OPI 1.3/2.0 proxy dicts, RichMedia params/sizing,
  RoleMap/RoleMapNS/ClassMap/StyleDict, StructureAttributesDict,
  StructureReference.

## [0.7.35] — 2026-08-24

### Added

* Parity batch 33 — 16 TSVs: PostScript/passthrough/PrinterMark/
  TrapNet form XObjects, stencil ImageMask, soft-mask image,
  XObjectMap; FontFile3 subtype split (Type1C/CIDFontType0C/OpenType);
  FontDescriptor TrueType/Type3 variants; SoftMaskAlpha/Luminosity,
  GraphicsStateParameterMap, GroupAttributes.

## [0.7.34] — 2026-08-24

### Added

* Parity batch 32 — media/rendition family complete (15 TSVs):
  RenditionMedia/Selector, RenditionMH/BE, MediaClipData mapping +
  MHBE, MediaClipSection(+MHBE), MediaDuration, MediaPermissions,
  MediaPlayParameters(+MH/BE), MediaScreenParametersMHBE.

## [0.7.33] — 2026-08-23

### Added

* Parity batch 31 — 20 TSVs: the six `/DecodeParms` dictionaries
  (Flate with predictor defaults, LZW EarlyChange, DCT color
  transform, CCITT group classification, JBIG2 globals, Crypt) and
  14 simple array types (gamma/whitepoint/trailer-ID/visibility-
  expression/related-files/RichMedia-command/UR-transform/universal).

### Fixed

* Name-typed Arlington defaults now materialize as Symbols.

## [0.7.32] — 2026-08-23

### Added

* Parity batch 30 — Requirements handler family (28 TSVs, s7.9.2):
  `RequirementsHandler` base + 27 per-feature subclasses.

## [0.7.31] — 2026-08-23

### Added

* Parity batch 29 — 18 TSVs: form-field family (Field, Choice,
  Text, Sig + Checkbox/Push/RadioButton), FileSpecEF/RF,
  EmbeddedFileParameter, MarkedContentReference, ObjectReference,
  Namespace (with its previously missing autoload), SoftwareIdentifier,
  Transition, ExData3DMarkup/MarkupGeo, PrinterMarkSubDict.

## [0.7.30] — 2026-08-23

### Added

* Parity batch 28 — 13 TSVs: ViewerPreferences, MarkInfo, IconFit,
  PagePiece, URI, URLAlias, URTransformParameters, DeviceN family,
  Separation, Measure→MeasureRL, new GeospatialMeasure.

### Fixed

* DeviceN/Separation accessors realigned with their TSV keys.

## [0.7.29] — 2026-08-23

### Added

* Parity batch 27 — 19 TSVs: shading family (ShadingCommon module,
  all seven ShadingTypes with stream-backed meshes, ShadingMap),
  PatternMap, OptContentUser/Zoom, OC configuration + usage dicts.

## [0.7.28] — 2026-08-23

### Added

* Parity batch 26 — 24 TSVs: font family (FontFile/2, CID fonts and
  descriptors, MultipleMaster, Encoding, ToUnicodeCMap,
  CIDFontDescriptorMetrics) and the full signature family (s12.8).

### Fixed

* `Signature#has_byte_range?` accepts field-wrapped PdfArray values.

## [0.7.27] — 2026-08-23

### Added

* Parity batch 25 — 27 TSVs mapped 1:1: functions (Type 0/2/3/4),
  halftones (1/5/6/10/16), RichMedia family, media offsets/players/
  criteria.

## [0.7.26] — 2026-08-23

### Added

* Parity batch 24 — color-space family (~20 TSVs): array-form
  color spaces (CalGray/CalRGB/Lab/Device*/ICCBased/Indexed/
  Separation/DeviceN/Pattern), BlackpointArray, ColorSpaceMap,
  ColorantsDict, BoxStyle; mappings for Cal/ICC/BoxColorInfo/
  PageLabel/LabRangeArray.

### Fixed

* Arlington default values are now type-converted (integers, floats,
  booleans, arrays) instead of raw TSV strings.

## [0.7.25] — 2026-08-20

### Added

* Parity batch 23 — destination family (11 TSVs): Destination base
  with fit predicates, XYZ/Fit/FitH/FitR + structure variants,
  DestinationDict, DestsMap; CryptFilter family mappings.
* `Cos::ArlingtonBacked` — shared TSV binding extracted so
  `PdfArray` subclasses gain positional `element_field` typing
  alongside Dictionary's field merging.

## [0.7.24] — 2026-08-19

### Added

* Parity batch 22 — Collection/Portfolio family complete (9 TSVs):
  CollectionColors, CollectionFolder, CollectionSplit,
  CollectionSubitem plus mappings on the five existing classes.

## [0.7.23] — 2026-08-18

### Added

* Parity batch 21 — ActionGoToE, three AddAction dictionaries
  (form-field/screen/widget trigger sets), ThreeD/Movie/Projection/
  TrapNetwork annotations; AppearanceTrapNet mapping fix.

## [0.7.22] — 2026-08-18

### Added

* Critical feature parity spec (27 examples) + `docs/USAGE.md`
  cookbook + `docs/SEMVER.md` policy.

## [0.7.21] — 2026-08-17

### Added

* Batch 20 — AddActionPageObject, BorderStyle; mappings for
  BorderEffect, CIDSystemInfo, WidgetAnnotation, Movie, SoundObject.

## [0.7.20] — 2026-08-17

### Added

* DSS (Document Security Store) + DPart types; mappings for 3D and
  appearance types.

## [0.7.19] — 2026-08-17

### Added

* `arlington_object` declarations on 41 existing annotation and
  action types (enabled by the 0.7.18 merge fix).

## [0.7.18] — 2026-08-16

### Fixed

* `arlington_object` / `define_field` merge: Arlington metadata now
  merges with hand-coded fields instead of replacing them, and the
  idempotency check compares against the parameter (anonymous
  classes previously skipped loading silently).

## [0.7.17] — 2026-08-16

### Added

* AddActionCatalog, AlternateImage, ActionSound types.

## [0.7.16] — 2026-08-16

### Added

* Thread, Bead, WebCapture family, TrapRegion types.

## [0.7.15] — 2026-08-14

### Added

* `Document#encryption` facade — `encrypt!`/`decrypt!` (40/128/256
  bit) and `.permission_bits`.

## [0.7.14] — 2026-08-14

### Added

* VRI, Thumbnail, Timespan, Viewport, UserProperty types.

### Fixed

* ArgumentError handling in signature verification on tampered DER.

## [0.7.13] — 2026-08-14

### Added

* BoxFitter wired to Frame area tracking; Content::Processor
  inline-image hook.

## [0.7.12] — 2026-08-14

### Fixed

* `Frame#find_available_area` always returned the top-left corner
  regardless of removed areas — rewrote with cursor tracking and
  overlap detection; fixes Composer multi-page flow.

## [0.7.11] — 2026-08-13

### Fixed

* GIF LZW next-code threshold; V5 user-password hash XOR.

## [0.7.10] — 2026-08-11

### Fixed

* Release workflow reverted to metanorma/ci `rubygems-release.yml`
  (the RubyGems trusted publisher is registered for that path).

## [0.7.9] — 2026-08-11

## [0.7.8] — 2026-08-10

### Added

* Parity batch 10 — CMS EnvelopedData public-key decryption,
  inline-image parser (BI/ID/EI with abbreviation expansion),
  forbidden-pattern cleanup.

## [0.7.7] — 2026-08-10

## [0.7.6] — 2026-08-09

### Added

* TIFF uncompressed decode, GIF LZW decode, complete sRGB ICC
  profile with real MD5 ProfileID, polygon inscribed scan.

## [0.7.5] — 2026-08-09

## [0.7.4] — 2026-08-09

### Added

* Batch-7 deepening: V5Writer wired, PKI handler registered, real
  glyph shaping and coverage reporting.

## [0.7.3] — 2026-08-09

## [0.7.2] — 2026-08-09

### Added

* Parity batches 4–6 — hyphenation, thumbnails, table spans and
  multi-page tables, tagged-PDF validation, multi-revision
  traversal, linearization-aware reader, PDF/A deep preflight,
  PDF/X-6 and PDF/VT conformance, 17-module bulk TODO completion
  across conformance/layout/encryption/fonts/images/color.

## [0.7.1] — 2026-08-08

## [0.7.0] — 2026-08-08

### Added — Release infrastructure

* `.github/workflows/rake.yml` — Metanorma CI generic-rake workflow
  for tests on every push, PR, tag, and dispatch.
* `.github/workflows/release.yml` — Metanorma CI rubygems-release
  workflow driven by `workflow_dispatch` with `next_version` input
  or `repository_dispatch` of type `do-release`.
* `RELEASE.md` — documents the publish flow and required secrets.

### Added — Image subsystem

* `Pdfrb::Image::Audit` — read-only metadata extractor (ImageInfo
  struct per image XObject) with `each_image`, `all`, `oversized`
  helpers.
* `Pdfrb::Image::Downsampler` — pure-Ruby nearest-neighbour for
  FlateDecode-encoded 8-bpc non-palette images. PNG predictor
  round-trip on both decode and encode. JPEG/JP2K skipped (no
  native deps).
* `Pdfrb::Task::Optimize#downsample_images!(factor:)` — applies the
  downsampler across every image XObject in the document.

### Added — Layout bidi

* `Pdfrb::Layout::Bidi` — paragraph-level UAX #9 bidi reordering
  (P2-P3 paragraph level, BD1 type classification, I1/I2 implicit
  levels, L2 reverse by level, L4 paired-bracket mirroring).
* `Pdfrb::Layout::TextLayouter#layout` calls `Bidi.reorder` before
  line breaking, so Hebrew and Arabic render in visual order.

### Fixed

* Issue #63: `Document::Fonts#add` now extracts the PostScript name
  (name table nameID 6) and uses it in `/BaseFont` (e.g.
  `ABCDEF+MinionPro-Regular` instead of `ABCDEF+EmbeddedFont3132`).
* Issue #64: `Model::Type::Resources#empty?` handles Hash, Array,
  Cos::Dictionary, and PdfArray values via a single
  `empty_collection?` helper.

### Changed

* `Pdfrb::Task::Optimize.dedup_streams!` now actually rewrites
  references to duplicate streams (was a stub).
* `Pdfrb::Writer#write_xref_stream` emits a free entry for every
  gap in the oid space, so dedup'd oids don't misalign the reader's
  per-oid index.
* `Pdfrb::Document::Form#flatten!` stamps each field's `/AP /N`
  appearance stream into the page content via the `/Do` operator
  (was a stubbed no-op).

## [0.3.0] — 2026-08-02

### Added — Semantic PDF diff

* **Pdfrb::Compare** — semantic PDF comparison engine. Compares two
  PDFs at the structural level: page count, per-page text similarity
  (Levenshtein), font inventory diffs, image count delta, outline
  (bookmark) diffs, metadata (/Info) diffs, and structural (Catalog +
  Trailer key) diffs.
* **Pdfrb::Compare::Report** — immutable report with `equivalent?`,
  `similarity` (0..1), `summary` string, and `to_h` serialisation.
* **CLI: `pdfrb diff LEFT RIGHT`** — compare two PDFs from the
  command line. Exits 0 if equivalent, 1 if different.
* **Programmatic API**: `Pdfrb::Compare.compare(left, right)` and
  `Pdfrb::Compare.equivalent?(left, right)`. Accepts bytes, IO, or
  Document objects.

### Metrics

* 550 specs (was 537), 0 failures, 4 pending.
* 0 rubocop offenses.
* 182 → 185 lib files; 49 → 50 spec files.

## [0.2.1] — 2026-08-02


### Added

* **Form XObjects** (`Document::FormXObject`) — create reusable form
  templates with a Canvas; register on pages and draw via /Do operator.
* **TTF subsetting** (`Font::TrueType::Subsetter`) — real glyph subsetting
  with composite glyph support, loca/glyf/cmap/hmtx rewriting, graceful
  fallback to full embedding.
* **Outline circular-reference fix** — bookmarks now store References
  (not raw Dictionaries), preventing infinite serialization recursion.
* **Document::Outline round-trips** — flat and nested outlines survive
  write + read correctly.

### Metrics

* 537 specs (was 534), 0 failures, 4 pending.
* 0 rubocop offenses.
* 180 → 182 lib files; 47 → 49 spec files.

## [0.2.0] — 2026-08-02


### Added — P0 feature implementations

* **CMap writer** (`Font::CMap::Writer`) — generates valid `/ToUnicode`
  CMap data from glyph-code → Unicode mappings. Supports 1-byte and
  2-byte codespaceranges, supplementary Unicode (UTF-16 surrogate pairs),
  multi-codepoint ligatures, and automatic chunking (≤100 entries per
  `beginbfchar`/`endbfchar` section per PDF spec). Round-trips through
  `Font::CMap::Parser`.

* **Document::Files** (Associated Files / EmbeddedFiles) — embeds files
  as `/Type /EmbeddedFile` streams referenced by `/Type /FileSpec` dicts,
  stored in the Catalog's `/Names /EmbeddedFiles` name tree. Supports
  MIME types, descriptions, and PDF 2.0 `/AF` relationship tagging.
  Round-trips through write + read.

* **XRef stream writer** (PDF 1.5+) — emits binary XRef streams instead
  of classical xref tables. Configurable via
  `config["writer.use_xref_stream"] = true`. `/W [1 3 1]` entry format
  with FlateDecode compression. Round-trips correctly.

* **Object stream packing** (`/Type /ObjStm`) — packs eligible small
  objects (non-stream, non-encrypted, < threshold bytes) into compressed
  object streams. Configurable via `config["writer.pack_object_streams"]
  = true` + `config["writer.object_stream_threshold"]`. Reduces file
  size by 20–50%.

* **Task::Optimize** — real implementation (was a no-op stub). Enables
  FlateDecode compression, XRef stream writing, and ObjStm packing in
  one call: `Pdfrb::Task::Optimize.call(doc, io: out)`.

* **Document::Outline** (bookmarks/outline write-side) — creates
  `/Outlines` tree on Catalog with flat and nested entries. Each entry
  has `/Title`, `/Parent`, `/First`/`/Last`/`/Next`/`/Prev` links.

* **Fixed CMap Parser** — regex bug: `beginbfchar` line matching didn't
  handle `N beginbfchar` format (with count prefix). Fixed to match
  anywhere in the line. Also added surrogate-pair decoding for
  supplementary Unicode CMaps.

### Configuration additions

```ruby
config["writer.use_xref_stream"]      # bool, default false
config["writer.pack_object_streams"]  # bool, default false
config["writer.object_stream_threshold"]  # int, default 200
```

### Metrics

* 534 specs (was 503), 0 failures, 6 pending.
* 0 rubocop offenses.
* ~85% line coverage.
* 178 → 180 lib files; 44 → 47 spec files.

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
