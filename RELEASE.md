# Releasing pdfrb

Releases are driven by the Metanorma CI reusable workflow at
`.github/workflows/release.yml`. It supports two triggers:

1. **`workflow_dispatch`** with a `next_version` input — manual run
   from the Actions UI. Accepted values: `x.y.z`, `major`, `minor`,
   `patch`, `pre|rc|etc`, or `skip` (release the current gemspec
   version as-is).
2. **`repository_dispatch`** with event type `do-release` — for
   automation triggers from other repos.

Both call
[`metanorma/ci/.github/workflows/rubygems-release.yml@main`](https://github.com/metanorma/ci/blob/main/.github/workflows/rubygems-release.yml),
which handles version bumping, tag creation, gem build, RubyGems
publish, and GitHub release creation.

## Authentication

The reusable workflow uses the `CLARICLE_CI_RUBYGEMS_API_KEY` secret
for RubyGems authentication. Ensure this secret is set in repo
Settings → Secrets and Variables → Actions.

The `GITHUB_TOKEN` is passed as `pat_token` for the version-bump
commit/tag/push steps.

## Triggering a release

### From the Actions UI

1. Go to Actions → `release` workflow.
2. Click "Run workflow".
3. Enter the next version (e.g., `0.8.0`, `patch`, `minor`, `major`).
4. Click "Run workflow".

### From the API / CI

```sh
gh workflow run release.yml \
  -f next_version=0.8.0
```

Or via `repository_dispatch` from another repo:

```sh
gh api /repos/claricle/pdfrb/dispatches \
  -f event_type=do-release \
  -f 'client_payload[next_version]=0.8.0'
```

## CI (test) workflow

`.github/workflows/rake.yml` runs the standard Metanorma CI
generic-rake workflow on every push to `main`/`master`, every tag
push, every pull request, and via manual `workflow_dispatch`.

`.github/workflows/ci.yml` (the original hand-rolled CI) is also
present as a fallback.

## Pre-release checklist

* `bundle exec rake` is green locally.
* `lib/pdfrb/version.rb` matches the intended release (the release
  workflow handles this automatically when given `next_version`).
* `CHANGELOG.md` has an entry for the new version.
* No uncommitted changes on `main`.
* `CLARICLE_CI_RUBYGEMS_API_KEY` secret is set in repo settings.
