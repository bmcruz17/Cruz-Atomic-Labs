require "minitest/autorun"
require_relative "support/content_rules"

class ContentRulesTest < Minitest::Test
  TODAY = Date.new(2026, 1, 15)

  def post(front_matter)
    "---\n#{front_matter}---\nHello.\n"
  end

  def test_front_matter_parses_yaml_block
    assert_equal({ "title" => "Hi" }, ContentRules.front_matter("---\ntitle: Hi\n---\nbody"))
  end

  def test_front_matter_is_nil_without_block
    assert_nil ContentRules.front_matter("# Just markdown\n")
  end

  def test_front_matter_rejects_invalid_yaml
    assert_raises(ContentRules::InvalidFrontMatter) do
      ContentRules.front_matter("---\ntitle: [unclosed\n---\n")
    end
  end

  def test_empty_config_is_valid
    assert_empty ContentRules.config_errors("")
    assert_empty ContentRules.config_errors("# only a comment\n")
  end

  def test_config_must_be_a_map
    assert_match(/key\/value map/, ContentRules.config_errors("- a\n- b\n").first)
  end

  def test_config_with_bad_yaml_is_reported
    assert_match(/not valid YAML/, ContentRules.config_errors("title: \"unterminated\n").first)
  end

  def test_page_needs_front_matter_and_title
    assert_empty ContentRules.page_errors("index.md", "---\ntitle: Home\n---\n")
    assert_match(/missing front matter/, ContentRules.page_errors("index.md", "Hello").first)
    assert_match(/no title/, ContentRules.page_errors("index.md", "---\nlayout: home\n---\n").first)
    assert_match(/no title/, ContentRules.page_errors("index.md", "---\ntitle: \"  \"\n---\n").first)
  end

  def test_valid_post_has_no_errors
    errors = ContentRules.post_errors("2026-01-10-first-post.md",
                                      post("title: \"First\"\ndate: 2026-01-10\n"), today: TODAY)
    assert_empty errors
  end

  def test_post_date_with_time_and_zone_is_accepted
    errors = ContentRules.post_errors("2026-01-10-first-post.md",
                                      post("title: First\ndate: 2026-01-10 09:30:00 -0500\n"), today: TODAY)
    assert_empty errors
  end

  def test_post_filename_must_follow_jekyll_convention
    ["first-post.md", "2026-1-10-first.md", "2026-01-10.md", "2026-01-10-first.txt"].each do |name|
      assert_match(/YYYY-MM-DD-title/, ContentRules.post_errors(name, post("title: x\n"), today: TODAY).first, name)
    end
  end

  def test_post_filename_date_must_be_real
    assert_match(/not a real calendar date/,
                 ContentRules.post_errors("2026-02-30-oops.md", post("title: x\n"), today: TODAY).first)
  end

  def test_post_needs_title_and_date
    errors = ContentRules.post_errors("2026-01-10-first.md", post("layout: post\n"), today: TODAY)
    assert_includes errors, "2026-01-10-first.md: front matter has no title"
    assert_includes errors, "2026-01-10-first.md: front matter has no date"
  end

  def test_post_date_must_match_filename
    errors = ContentRules.post_errors("2026-01-10-first.md", post("title: x\ndate: 2026-01-11\n"), today: TODAY)
    assert_equal ["2026-01-10-first.md: front matter date 2026-01-11 does not match filename date 2026-01-10"], errors
  end

  def test_post_with_unparseable_date_is_reported
    errors = ContentRules.post_errors("2026-01-10-first.md", post("title: x\ndate: soon\n"), today: TODAY)
    assert_match(/not a valid date/, errors.first)
  end

  def test_future_post_is_flagged_unless_allowed
    text = post("title: x\ndate: 2026-02-01\n")
    assert_match(/in the future/, ContentRules.post_errors("2026-02-01-later.md", text, today: TODAY).first)
    assert_empty ContentRules.post_errors("2026-02-01-later.md", text, today: TODAY, future_allowed: true)
  end

  def test_post_without_front_matter_is_reported
    assert_match(/missing front matter/,
                 ContentRules.post_errors("2026-01-10-first.md", "Just text", today: TODAY).first)
  end
end
