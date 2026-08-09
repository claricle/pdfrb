# Releasing pdfrb

Releases are driven by the workflow at `.github/workflows/release.yml`,
modelled on the emf2svg-ruby release flow. It supports two triggers:

1. **`workflow_dispatch`** with a `bump-type` choice (`current`,
   `patch`, `minor`, `major`). The workflow bumps `lib/pdfrb/version.rb`,
   commits, tags `vX.Y.Z`, and pushes both. The tag push then triggers
   the publish path.
2. **`push` to `v*` tags** — fires the publish path directly when you
   push a tag yourself.

## Authentication: OIDC Trusted Publishing

The publish job uses
[`rubygems/configure-rubygems-credentials@main`](https://github.com/rubygems/configure-rubygems-credentials)
to mint short-lived push credentials from GitHub's OIDC token. No
long-lived API key is stored in repo secrets.

Required GitHub workflow permissions:
```yaml
permissions:
  contents: write   # push bump commit + tag
  id-token: write   # RubyGems OIDC
```

Required RubyGems trusted-publisher setup (one-time, on
https://rubygems.org/gems/pdfrb/settings/trusted_publishers):

- Repository owner: `claricle`
- Repository name: `pdfrb`
- Workflow filename: `release.yml`
- Environment name: (leave blank)

## Triggering a release

### From the Actions UI

1. Go to Actions → `release` workflow.
2. Click "Run workflow".
3. Pick `bump-type` (default `patch`).
4. Click "Run workflow".

### From the API

```sh
gh workflow run release.yml -f bump-type=patch
```

The workflow bumps, tags, pushes the tag, then builds and publishes.
Total runtime ~3 minutes.

### Pushing a tag directly

If `lib/pdfrb/version.rb` was already bumped via a merged PR, just
push the matching tag and the publish path runs:

```sh
git tag v$(ruby -Ilib -e 'require "pdfrb/version"; print Pdfrb::VERSION')
git push origin v<VERSION>
```

## Pre-release checklist

* `bundle exec rake` is green locally.
* `CHANGELOG.md` has an entry for the new version.
* No uncommitted changes on `main`.
* The RubyGems trusted publisher is configured for `claricle/pdfrb`
  with workflow filename `release.yml` (one-time setup).
