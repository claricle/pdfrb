# Pdfrb Semver Policy

## Version Scheme

Pdfrb follows [Semantic Versioning 2.0.0](https://semver.org/).

- **MAJOR** (X.0.0): Breaking API changes. Existing code that depends
  on pdfrb may need updates.
- **MINOR** (0.X.0): New features, backward-compatible. Existing code
  continues to work.
- **PATCH** (0.0.X): Bug fixes, performance improvements, doc updates.
  No new features, no breaking changes.

## Current Phase: 0.x (pre-1.0)

During 0.x development, the API is not yet frozen. Minor version bumps
 MAY include breaking changes, but they will be documented in
CHANGELOG.md with migration notes.

The goal is to reach 1.0 once:
- The public API is stable (Document, Writer, Canvas, Conformance).
- Round-trip is proven against a broad fixture corpus.
- All P0 TODOs are complete.
- veraPDF cross-check passes on PDF/A output.

## Deprecation Policy

1. A deprecated API is marked with YARD `@deprecated` tags and emits a
   `Warning.warn` on first use.
2. The deprecation period lasts at least one minor version.
3. Removal happens in the next major version bump.

## Release Checklist

- [ ] All specs pass: `bundle exec rake`
- [ ] Rubocop clean: `bundle exec rubocop`
- [ ] Coverage maintained or improved: `COVERAGE=1 bundle exec rspec`
- [ ] CHANGELOG.md updated with all changes
- [ ] Version bumped in `lib/pdfrb/version.rb`
- [ ] Git tag created: `vX.Y.Z`
- [ ] Gem pushed: `gem build && gem push`

## Public API Stability Contract

The following are considered **stable** (subject to semver guarantees):

- `Pdfrb::Document` — top-level facade (new, open, write, pages, fonts, etc.)
- `Pdfrb::Writer` — serialization
- `Pdfrb::Serializer` — COS-to-bytes
- `Pdfrb::Canvas` — content-stream drawing
- `Pdfrb::Compare` — semantic diff
- `Pdfrb::Conformance` — PDF/A and PDF/UA validators
- `Pdfrb::DigitalSignature` — signing and verification
- `Pdfrb::Error` hierarchy

The following are **internal** (may change without notice):

- `Pdfrb::Source::*` — tokenizer/parser internals
- `Pdfrb::Model::Cos::*` — COS implementation details
- `Pdfrb::Arlington::*` — predicate evaluation internals
