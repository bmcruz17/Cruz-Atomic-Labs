# Merge-ready review of open PRs

Reviewed 2026-10-24. Repo: bmcruz17/Cruz-Atomic-Labs (a Jekyll / GitHub Pages site started from the GitHub Skills exercise). Default branch: `main`.

Only **one** PR was open when this was written (#11). This review's own PR is not counted.

## Does merging to main deploy to production?

No. Nothing in `.github/workflows/` deploys. GitHub Pages is not enabled (per #11's own audit, exercise Step 1), there are no edge functions, no Cloudflare config, no database and no SQL. Merging deploys nothing by itself.

One side effect: the exercise workflows `2-step.yml` and `3-step.yml` run on pushes to `main` that touch `index.md` or `_config.yml`. Merging #11 changes `_config.yml`, so `3-step.yml` will run once. It only uses `GITHUB_TOKEN` to read and to comment on the exercise issue. If Pages is later enabled, `main` would publish to the live site on each push.

## Dependency order

There is no PR chain. #11 is based on `main` and `main` is an ancestor of its head, so it fast-forwards cleanly (`git merge-base --is-ancestor origin/main pr-11` was true; GitHub reports it MERGEABLE).

## Per-PR verdicts

### #11 Repo audit: local build, tests, CI, README, docs/AUDIT.md (draft, `burn/repo-audit` -> `main`)

**Verdict: SAFE TO MERGE NOW** (after Brandon marks it ready for review, since it is a draft; it only needs a click, no code changes).

- **What it changes:** Gemfile and lockfile, `_config.yml` (excludes and the sitemap plugin), `.gitignore`, a Rakefile, tests under `test/`, a PR-only CI workflow, a Dependabot bundler entry, README, `docs/AUDIT.md`.
- **Touches none of the risky areas:** no auth, payments, SQL, migrations or RLS, Cloudflare config, secrets, live email/SMS, or pricing. The new workflow `site-check.yml` has `contents: read`, runs on pull requests only and never deploys. It uses only the built-in `github.token`.
- **Test result:**
  - GitHub CI "Site check / Build and test" **passed** on the PR head (completed 2026-10-24 13:06 UTC).
  - The PR author reports `bundle exec rake test`: 27 runs, 0 failures, 2 skips.
  - **I did not re-run the tests locally.** `bundle install` was not permitted in this environment, so no local gems were installed. Ruby and Bundler exist on this Mac, but the dependencies could not be fetched. I relied on the GitHub CI run plus a static read of the config, Gemfile, Rakefile and workflow files, which contain nothing unexpected.
  - There is no `package.json`, so the `npm` steps in the brief don't apply.
  - Supabase CLI, Docker, psql and Playwright were not needed and are not installed.
- **Merge cleanliness:** clean fast-forward onto current `main`.
- **What merging deploys:** nothing. No SQL to apply by hand, no edge functions.
- **Things to know:** the PR's open questions (site title and description, license holder, a `rubyzip` advisory pulled in by `github-pages` 232, enabling Pages) are content decisions in its description. None of them block the merge.

## Exact merge order

1. #11, and nothing else.

## CLOSE AS SUPERSEDED

None.

## NEEDS BRANDON

None for risk reasons. The only decision is whether to take #11 out of draft and merge it.

## Patches

No fixes were needed, so `docs/merge-ready-patches/` was not created.
