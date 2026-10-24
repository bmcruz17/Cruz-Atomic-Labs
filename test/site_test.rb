require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "jekyll"
require "html-proofer"
require "nokogiri"
require_relative "support/content_rules"

class SiteTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  # Build once for the whole run via the CLI, so the github-pages gem applies the
  # same defaults (theme, plugins) that GitHub Pages does.
  def self.built_site
    @built_site ||= begin
      dest = Dir.mktmpdir("site-test")
      Minitest.after_run { FileUtils.remove_entry(dest) }
      built = system("bundle", "exec", "jekyll", "build", "--quiet", "--destination", dest, chdir: ROOT)
      raise "jekyll build failed; run `bundle exec jekyll build` to see why" unless built

      config = Jekyll.configuration("source" => ROOT, "destination" => dest, "quiet" => true)
      { dest: dest, config: config }
    end
  end

  def dest
    self.class.built_site[:dest]
  end

  def config
    self.class.built_site[:config]
  end

  def home
    @home ||= Nokogiri::HTML(File.read(File.join(dest, "index.html")))
  end

  def test_config_is_valid_yaml
    assert_empty ContentRules.config_errors(File.read(File.join(ROOT, "_config.yml")))
  end

  def test_homepage_source_has_front_matter_and_title
    assert_empty ContentRules.page_errors("index.md", File.read(File.join(ROOT, "index.md")))
  end

  def test_posts_follow_jekyll_rules
    posts = Dir.glob(File.join(ROOT, "_posts", "*"))
    skip "no posts in _posts/ yet" if posts.empty?

    errors = posts.flat_map do |path|
      ContentRules.post_errors(File.basename(path), File.read(path), future_allowed: config["future"])
    end
    assert_empty errors, errors.join("\n")
  end

  def test_homepage_is_built
    assert File.exist?(File.join(dest, "index.html")), "index.html was not generated"
  end

  def test_repo_only_files_are_not_published
    %w[README.md LICENSE docs test Gemfile Gemfile.lock Rakefile vendor].each do |path|
      refute File.exist?(File.join(dest, path)), "#{path} should not be published to the site"
    end
  end

  def test_sitemap_is_generated
    assert File.exist?(File.join(dest, "sitemap.xml")), "sitemap.xml was not generated"
  end

  def test_homepage_declares_language
    lang = home.at("html")&.[]("lang").to_s
    refute_empty lang.strip, "<html> needs a lang attribute for screen readers"
  end

  def test_homepage_has_title
    refute_empty home.at("title")&.text.to_s.strip, "homepage has no <title>"
  end

  def test_homepage_has_exactly_one_h1
    assert_equal 1, home.css("h1").size, "homepage should have exactly one <h1>"
  end

  def test_homepage_has_meta_description
    skip "TODO(Brandon): set `description` in _config.yml" if ContentRules.blank?(config["description"])

    refute_empty home.at('meta[name="description"]')&.[]("content").to_s.strip
  end

  # Internal links, image alt text, and script references. External links are
  # skipped so the suite does not depend on third-party sites being up; run
  # `bundle exec rake proof_external` to check them.
  def test_built_html_passes_htmlproofer
    proofer = HTMLProofer.check_directory(dest, disable_external: true, log_level: :fatal)
    begin
      proofer.run
    rescue SystemExit
      # HTML-Proofer calls exit(1) on failure, which would end the whole test run.
    end
    failures = proofer.failed_checks.map { |f| "#{f.path.delete_prefix(dest)}:#{f.line} #{f.description}" }
    assert_empty failures, failures.join("\n")
  end
end
