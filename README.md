# Cruz-Atomic-Labs

Source for a [GitHub Pages](https://docs.github.com/en/pages) site built with
[Jekyll](https://jekyllrb.com/). The repository was created from the GitHub Skills
"GitHub Pages" exercise template.

<!-- TODO(Brandon): one or two sentences on what this site is for. -->

**Status**

- The exercise is in progress at Step 1. Instructions are in
  [issue #1](https://github.com/bmcruz17/Cruz-Atomic-Labs/issues/1).
- GitHub Pages is **not enabled** yet, so there is no live site.
  Once it is, the address will be shown under **Settings → Pages**.

[![Go to the exercise (issue #1)](https://img.shields.io/badge/Go%20to%20Exercise-%E2%86%92-1f883d?style=for-the-badge&logo=github&labelColor=197935)](https://github.com/bmcruz17/Cruz-Atomic-Labs/issues/1)

## What's in here

| Path | Purpose |
| --- | --- |
| `index.md` | Homepage content (Markdown with YAML front matter). |
| `_config.yml` | Jekyll site settings: plugins and files excluded from the site. |
| `_posts/` | Blog posts, named `YYYY-MM-DD-title.md` (created in exercise Step 4). |
| `Gemfile`, `Gemfile.lock` | Ruby gems, pinned to the `github-pages` gem so local builds match GitHub Pages. |
| `Rakefile`, `test/` | Test suite (see below). |
| `.github/workflows/site-check.yml` | CI: builds the site and runs the tests on every pull request. It does not deploy. |
| `.github/workflows/[0-4]-*.yml`, `.github/steps/` | GitHub Skills exercise automation. It posts instructions to issue #1 as you complete steps. |
| `docs/AUDIT.md` | Latest repo audit: findings, fixes, and open questions. |

## Run it locally

You need Ruby 3.2 or newer (GitHub Pages currently uses 3.3; see
[pages.github.com/versions](https://pages.github.com/versions/)) and Bundler.

```bash
bundle install
bundle exec jekyll serve
```

Then open <http://127.0.0.1:4000>. The site rebuilds when you save a file
(changes to `_config.yml` need a restart).

You may see `GitHub Metadata: No GitHub API authentication could be found`. That
warning is harmless. To silence it, export a GitHub token with no extra scopes as
`JEKYLL_GITHUB_TOKEN`.

## Test it

```bash
bundle exec rake test
```

This builds the site with the same gems GitHub Pages uses, then checks:

- `_config.yml` and the front matter in `index.md` are valid YAML, and the homepage has a title.
- Every post in `_posts/` has a valid `YYYY-MM-DD-title.md` filename, a `title`, and a `date`
  that matches the filename. It also checks the date isn't in the future, because
  GitHub Pages silently skips future-dated posts.
- The built HTML has no broken internal links or images, every image has alt text,
  the page declares a language, and the homepage has a `<title>` and exactly one `<h1>`.
- Repo-only files (`README.md`, `docs/`, `test/`, `Gemfile`, and so on) are not published.

Some tests are reported as **skipped** until there is content for them, for example
when there are no posts yet. Skips are listed when you run with `TESTOPTS=--verbose`.

To also check external links (needs network):

```bash
bundle exec rake proof_external
```

## Publish

Publishing is done by GitHub Pages, not by this repo's CI. Enable it under
**Settings → Pages → Deploy from a branch → `main`** (exercise Step 1). After that,
every push to `main` rebuilds the site.

## License

[MIT](LICENSE). The copyright line (`GitHub, Inc.`) was inherited from the exercise
template. <!-- TODO(Brandon): decide the copyright holder for your own content. -->
