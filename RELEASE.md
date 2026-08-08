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

## Authentication: OIDC Trusted Publishing

The release workflow uses **RubyGems OIDC Trusted Publishing** — no
stored API key. The reusable workflow auto-discovers the trusted
publisher via `rubygems/configure-rubygems-credentials@v2.1.0`.

To enable (one-time setup on RubyGems):

1. Sign in to https://rubygems.org.
2. Open the gem settings for `pdfrb` (you must be an owner).
3. Add a trusted publisher:
   - **Repository owner**: `claricle`
   - **Repository name**: `pdfrb`
   - **Workflow filename**: `release.yml`
   - **Environment name**: (leave blank)
4. Save.

Once configured, the workflow's `OIDC preflight — verify Trusted
Publisher auto-discovery` step will succeed and subsequent steps
(`Configure RubyGems credentials for Trusted Publishing`, `Build and
push gem (OIDC)`) run instead of the API-key path.

## Required secrets

The workflow call passes only `pat_token` (the workflow's own
`GITHUB_TOKEN`), used for tag/commit/git-push operations during the
release. No RubyGems API key is required.

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
push, every pull request, and via manual `workflow_dispatch`. It
fires the test matrix across supported Ruby versions.

`.github/workflows/ci.yml` (the original hand-rolled CI) is kept as
a fallback and is currently still active.

## Pre-release checklist

* `bundle exec rake` is green locally.
* `CHANGELOG.md` has an entry for the new version.
* No uncommitted changes on `main`.
* The RubyGems trusted publisher is configured for `claricle/pdfrb`
  with workflow filename `release.yml` (one-time setup).
