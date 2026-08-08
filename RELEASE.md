# Releasing pdfrb

Releases are driven by git tags. The release workflow is at
`.github/workflows/release.yml` and runs on tag push (or manual dispatch
for an existing tag).

## Publish flow

1. Ensure `lib/pdfrb/version.rb` has the target version.
2. Merge the version-bump change via a PR (never commit directly to main).
3. When the PR lands, tag the merged commit:

   ```sh
   git tag v$(ruby -Ilib -e 'require "pdfrb/version"; print Pdfrb::VERSION')
   git push origin v<VERSION>
   ```

4. The `Release` workflow fires automatically:
   - Verifies tag ↔ `lib/pdfrb/version.rb` match.
   - Builds the gem (`bundle exec rake build`).
   - Publishes to RubyGems via OIDC trusted publishing (no stored API key).
   - Creates a GitHub release with auto-generated notes.

## Trusted publishing (OIDC)

The workflow uses `rubygems/configure-rubygems-credentials` with OIDC.
To enable, on RubyGems:

1. Open the `pdfrb` gem settings.
2. Add the GitHub workflow as a trusted publisher:
   - Repository: `claricle/pdfrb`
   - Workflow filename: `release.yml`
   - Environment: (leave blank)

Until that is configured, the `Publish to RubyGems` step will fail.

## Manual dispatch

The workflow accepts a `tag` input. Run it from the Actions UI on a
previously-pushed tag if the auto-trigger missed (e.g., the workflow
file was added after the tag was pushed).

## Pre-release checklist

- `bundle exec rake` is green.
- `lib/pdfrb/version.rb` matches the intended tag.
- `CHANGELOG.md` has an entry for the new version.
- No uncommitted changes on `main`.
