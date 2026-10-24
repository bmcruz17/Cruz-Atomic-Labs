# Repo audit: Cruz-Atomic-Labs

- **Date:** 2026-10-24
- **Base:** `main` at `63329dd`
- **Branch:** `burn/repo-audit`

## What this repo is

This repo is a Jekyll site for GitHub Pages, created from the GitHub Skills
"GitHub Pages" exercise template. At audit time:

- The site content is a front-matter-only `index.md` and an empty `_config.yml`.
- There is no application code, no `package.json`, and no tests.
- The exercise is at Step 1 (issue #1 is open). Only the `Step 1` workflow is active; Steps 0, 2, 3 and 4 are disabled.
- GitHub Pages is **not enabled**. `GET /repos/bmcruz17/Cruz-Atomic-Labs/pages` returns 404, and `https://bmcruz17.github.io/Cruz-Atomic-Labs/` returns 404.
- There were no open PRs, so no files were off-limits.

Because of this, the audit treats the repo as a site. It covers accessibility, SEO
basics, links, build and test tooling, workflow and dependency hygiene, and docs.
Line numbers below refer to `main` unless marked *(branch)*.

## Summary

| # | Area | Finding | Status |
| --- | --- | --- | --- |
| 1 | Docs / a11y | README was exercise boilerplate with no run/test instructions; images lacked alt text | **Fixed** |
| 2 | Site output | `README.md` and `LICENSE` were published as raw files | **Fixed** |
| 3 | SEO | No sitemap | **Fixed** |
| 4 | Tests | No way to build or test locally; no tests or CI | **Fixed** |
| 5 | Hygiene | `.gitignore` missing Jekyll/Bundler outputs | **Fixed** |
| 6 | Dependencies | Dependabot only watched GitHub Actions | **Fixed** |
| 7 | SEO | No site title/description; generic page title; description depends on a network call | Proposed, **needs Brandon** |
| 8 | Content / a11y | Homepage has no body content | Proposed, **needs Brandon** |
| 9 | A11y | Default theme has no `<main>` landmark; no theme chosen | Proposed, **needs Brandon** |
| 10 | Hosting | GitHub Pages not enabled | **Needs Brandon** (hosting change, not done) |
| 11 | Security | `rubyzip` 2.4.1 advisory (via `github-pages`) | Proposed, **needs Brandon** |
| 12 | Workflows | Exercise template checkout pinned to `v0.4.0` while the reusable workflows use `v0.7.3` | Proposed |
| 13 | Supply chain | Third-party actions pinned by tag, not commit SHA | Proposed, **needs Brandon** |
| 14 | Workflows | Step 0 overwrites `index.md` on every push to `main` if re-enabled | Proposed (informational) |
| 15 | Dead code | Exercise scaffolding stays after the exercise ends | Proposed, **needs Brandon** |
| 16 | Legal | LICENSE copyright holder is GitHub, Inc. | **Needs Brandon** |
| 17 | Hygiene | `.gitignore` ignores `*.com` | Proposed (minor) |
| 18 | Content | Typo in exercise step text | Proposed (minor) |
| 19 | Site | No 404 page or favicon | Proposed (minor) |

The audit found no broken links. Every URL in `README.md` and `.github/steps/*.md`
returned HTTP 200, except the Pages URL, which is expected (see #10).

## Fixed in this branch

### 1. README did not tell a newcomer how to run or test anything

- `README.md:1-15`: the exercise's welcome message, with no description, setup, or test steps.
- `README.md:3`: the `<img>` had no `alt` attribute.
- `README.md:11`: the badge image had empty alt text (`![](...)`) inside a link, so the link had no accessible name for screen readers.

**Fix:** I rewrote the README. It covers what the repo is, the current status (the
exercise step and that Pages is not enabled), the repo layout, how to run locally,
how to test, how publishing works, and the license. The badge now has alt text and
the decorative Octocat image is gone. Unknowns are marked `TODO(Brandon)`.

### 2. Repo files were published as part of the website

`_config.yml` (empty on `main`): a baseline `jekyll build` copied `README.md` and
`LICENSE` into `_site/` as raw files. Any new repo files would have been published
the same way, including `docs/AUDIT.md`, `test/`, and `Gemfile`.

**Fix:** `_config.yml:15-24` *(branch)* adds an `exclude:` list. The test
`test_repo_only_files_are_not_published` guards it.

### 3. No sitemap

There was no `sitemap.xml`, which search engines use to discover pages.

**Fix:** `_config.yml:12-13` *(branch)* enables `jekyll-sitemap`. It is on the
GitHub Pages plugin allow-list, so it works on the hosted build with no extra
setup. The test `test_sitemap_is_generated` covers it.

### 4. No local build, tests, or CI

There was no `Gemfile`, so nobody could reproduce the GitHub Pages build locally,
and nothing checked content before it reached `main`.

**Fix:**

- **`Gemfile` / `Gemfile.lock`:** pinned to `github-pages ~> 232`, the version GitHub
  Pages currently runs (Jekyll 3.10.0, per https://pages.github.com/versions.json).
  `webrick` is added for `jekyll serve` on Ruby 3+. `html-proofer`, `minitest`, and
  `rake` are in the test group.
- **`test/support/content_rules.rb`:** pure functions for the Jekyll rules that make
  Pages fail a build or silently drop content:
  - valid `_config.yml`
  - page front matter and title
  - post filename format (`YYYY-MM-DD-title.md`) with a real date
  - required `title` and `date`, with the date matching the filename
  - future-dated posts, which Pages skips unless `future: true`
- **`test/content_rules_test.rb`:** 16 unit tests for those rules, covering good and bad fixtures.
- **`test/site_test.rb`:** builds the site through `bundle exec jekyll build` (same
  gems and defaults as Pages), applies the rules to the real files, then checks the
  built HTML:
  - HTML-Proofer: internal links, images, alt text, scripts
  - `<html lang>`, a non-empty `<title>`, and exactly one `<h1>`
  - excluded files are not published
  - a sitemap exists
- **`Rakefile`:** `rake test` (the default) and `rake proof_external`, an opt-in
  external link check that needs network.
- **`.github/workflows/site-check.yml`:** runs `bundle exec rake test` on pull
  requests and on manual dispatch. It has `contents: read` only and never deploys.
  It uses the built-in `github.token` only to avoid API rate limits in
  `jekyll-github-metadata`; no secrets were added.

**Honest failure handling:**

- HTML-Proofer's `run` calls `exit(1)` on failure, which would end the test process
  partway through. The test catches that and reports HTML-Proofer's own failure list
  as a normal assertion failure.
- Checks that have nothing to check yet, such as posts or a meta description, are
  reported as **skipped** with a reason, rather than silently passing.
- I confirmed the suite catches real problems. I temporarily added a post whose
  front matter date didn't match its filename, an image with no alt text pointing to
  a missing file, and a broken internal link. The suite failed with a specific
  message for each, then I reverted the changes.

### 5. `.gitignore` missing build outputs

`.gitignore:1-38` had only generic OS and archive patterns.

**Fix:** added `_site/`, `.jekyll-cache/`, `.jekyll-metadata`, `.sass-cache/`,
`.bundle/`, and `vendor/`.

### 6. Dependabot did not cover the new Ruby dependencies

`.github/dependabot.yml:3-6` covered `github-actions` only.

**Fix:** added a monthly `bundler` entry, so `Gemfile.lock` gets update PRs.

## Proposed, not changed

### 7. Site identity and SEO metadata (needs Brandon)

- `_config.yml` has no `title` or `description`.
- The rendered `<title>` is `Welcome to my blog! | Cruz-Atomic-Labs`. "Welcome to my blog!" comes from `index.md:2` (exercise default) and the suffix is the repo name.
- `<meta name="description">` is `CA Labs`, the GitHub repo description. `jekyll-github-metadata` fetches it at build time, so an offline build has no description.

**Proposal:** Brandon picks a site `title` and a one-sentence `description` and adds
them to `_config.yml`. There's a commented TODO there. Once a description is set,
the skipped test `test_homepage_has_meta_description` starts enforcing it. I didn't
invent wording.

### 8. Homepage has no content (needs Brandon)

`index.md:1-3` is front matter only. Visitors would see just the site name heading
and a footer. Writing the homepage is exercise Step 2.

### 9. Theme and the missing `<main>` landmark (needs Brandon)

- No `theme:` is set, so Pages uses its default, `jekyll-theme-primer`.
- Primer's `_layouts/default.html` (in the 0.6.0 gem) has no `<main>` landmark, so screen-reader users can't jump straight to the content.
- `minima` 2.5.1, the theme exercise Step 3 asks for, has `<main class="page-content" aria-label="Content">` at `_layouts/default.html:10`.

**Proposal:** add the minima theme as Step 3 instructs. I left this for Brandon so
the exercise's automated check (`.github/workflows/3-step.yml:49-55`) runs on his
commit. I also avoided writing the exact phrase that check looks for anywhere in
`_config.yml`, so the check can't pass by accident.

### 10. GitHub Pages is not enabled (needs Brandon; hosting change)

This is exercise Step 1: **Settings → Pages → Deploy from a branch → `main`**.
`.github/workflows/1-step.yml:3-5` waits for the `page_build` event. I didn't change
anything here, per the no-hosting-changes constraint.

After Pages is enabled, check one thing: in a local build without a GitHub token,
the Primer footer's "Improve this page" link points at `edit/gh-pages/index.md`. On
GitHub Pages it should use the real source branch, `main`. Confirm on the live site.

### 11. `rubyzip` 2.4.1 security advisory (needs Brandon)

`bundle-audit check --update` reports:

- **Advisory:** CVE-2026-85396 / GHSA-47m2-wp7j-p9vc, rated High: path traversal in rubyzip before 3.4.0.
- **Locked version:** `Gemfile.lock:315`, `rubyzip (2.4.1)`.
- **Dependency chain:** `github-pages 232` pins `jekyll-remote-theme 0.4.3` (`Gemfile.lock:197`), which requires `rubyzip (>= 1.3.0, < 3.0)` (`Gemfile.lock:201`).

The fix needs a major-version jump (2 to 3), which `jekyll-remote-theme` 0.4.3 doesn't
allow, and diverging from `github-pages` would break build parity. Exposure is
limited:

- The gem is used only on your machine and in CI, not by the published site.
- It only runs when `remote_theme:` is configured, which this site doesn't do.
- GitHub runs its own Pages build.

**Proposal:** accept for now and take the `github-pages` update when Dependabot
offers one with `rubyzip >= 3.4`. `bundle-audit` isn't wired into CI because this
advisory would fail it permanently. Run it by hand with
`gem install bundler-audit && bundle-audit check --update`.

**npm audit:** not applicable. The repo has no `package.json` or Node dependencies.

### 12. Exercise template checkout pinned to an older toolkit version

The workflows check out `skills/exercise-toolkit` markdown templates with
`ref: v0.4.0`:

- `0-start-exercise.yml:73`
- `1-step.yml:36`
- `2-step.yml:40`
- `3-step.yml:39` and `:114`

The reusable workflows they call use `@v0.7.3` (e.g. `1-step.yml:18`). Dependabot
doesn't update `ref:` inputs. All four template paths used exist at both tags, so
nothing is broken today.

**Proposal:** bump the `ref:` values to `v0.7.3`. Not done, because the exercise is
in progress and template wording may differ between versions.

### 13. Actions pinned by tag, not commit SHA (needs Brandon)

- `EndBug/add-and-commit@v9` runs with `contents: write` (`0-start-exercise.yml:49`, permissions at `:8-11`).
- `skills/action-text-variables@v3`, `skills/action-keyphrase-checker@v1` (`3-step.yml:52`), and the new `ruby/setup-ruby@v1` are also pinned by tag.

A moved tag could run different code.

**Proposal:** pin third-party actions to full commit SHAs. Dependabot can still bump
them. The risk is low for a personal exercise repo, and the exercise workflows are
template-owned, so this is Brandon's call.

### 14. Step 0 would overwrite `index.md` if re-enabled (informational)

- `0-start-exercise.yml:3-6` runs on every push to `main`, with no path filter.
- Its `create_initial_files` job (`:41-47`) runs `cat > index.md`, replacing the homepage, and commits the result (`:48-55`).

It's currently `disabled_manually`, as the toolkit leaves it, so it's harmless.
**Don't re-enable it** once the homepage has real content.

### 15. Exercise scaffolding becomes dead code (needs Brandon)

After the exercise finishes, or if it's abandoned, these do nothing for the site:

- `.github/steps/*.md`
- `.github/workflows/0-start-exercise.yml` through `4-step.yml`

**Proposal:** delete them in a follow-up PR once issue #1 is closed. The README and
this audit reference them, so update both then.

### 16. LICENSE copyright holder (needs Brandon)

`LICENSE:1` reads `Copyright (c) GitHub, Inc.`, inherited from the template. Brandon's
own content would sit under GitHub's copyright line. I made no change because this is
a legal choice. TODO(Brandon): decide the license and copyright holder for this site.

### 17. `.gitignore` ignores `*.com` (minor)

`.gitignore:3`, under "Compiled source", ignores any file whose name ends in `.com`,
such as a file named after a domain. Nothing is affected today. Remove the line if it
ever gets in the way.

### 18. Typo in exercise text (minor)

`.github/steps/3-step.md:44` has a stray backtick: ``the `main` branch`.``. This is
template content posted to issue #1, so I left it alone.

### 19. No 404 page or favicon (minor)

GitHub Pages shows its generic 404 page, and the Primer theme's favicon line is
commented out. Add a custom `404.md` and a favicon once the site identity (#7) is
decided.

## How this was verified

| Check | Result |
| --- | --- |
| `bundle exec rake test` (Ruby 3.2.3 locally; CI uses 3.3) | 27 runs, 0 failures, 2 skips (no posts yet; description TODO) |
| Same suite with deliberately broken content | Failed with a specific message for each problem, then reverted |
| `bundle exec rake proof_external` | Passed |
| `actionlint` on all workflows | Clean |
| `bundle-audit check --update` | 1 advisory (#11) |
| `curl` on every URL in README and step files | All 200, except the Pages URL (#10) |
