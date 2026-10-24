require "date"
require "yaml"

# Checks for the Jekyll content rules that, when broken, make GitHub Pages fail
# the build or silently skip a page or post.
module ContentRules
  FRONT_MATTER = /\A---\s*\n(.*?\n?)^(?:---|\.\.\.)\s*$\n?/m
  POST_FILENAME = /\A(\d{4}-\d{2}-\d{2})-([^\s\/]+)\.(?:md|markdown)\z/
  YAML_CLASSES = [Date, Time].freeze

  class InvalidFrontMatter < StandardError; end

  module_function

  # Returns the front matter as a Hash, or nil when the file has none.
  def front_matter(text)
    match = FRONT_MATTER.match(text)
    return nil unless match

    data = YAML.safe_load(match[1], permitted_classes: YAML_CLASSES) || {}
    raise InvalidFrontMatter, "front matter is not a key/value map" unless data.is_a?(Hash)

    data
  rescue Psych::Exception => e
    raise InvalidFrontMatter, "front matter is not valid YAML (#{e.message.lines.first.strip})"
  end

  def config_errors(text)
    data = YAML.safe_load(text, permitted_classes: YAML_CLASSES)
    return [] if data.nil? || data.is_a?(Hash)

    ["_config.yml must be empty or a key/value map, got #{data.class}"]
  rescue Psych::Exception => e
    ["_config.yml is not valid YAML (#{e.message.lines.first.strip})"]
  end

  def page_errors(name, text)
    data = front_matter(text)
    return ["#{name}: missing front matter (Jekyll would publish it as a raw file)"] if data.nil?

    blank?(data["title"]) ? ["#{name}: front matter has no title"] : []
  rescue InvalidFrontMatter => e
    ["#{name}: #{e.message}"]
  end

  def post_errors(name, text, today: Date.today, future_allowed: false)
    match = POST_FILENAME.match(name)
    return ["#{name}: filename must look like YYYY-MM-DD-title.md"] unless match

    file_date = parse_date(match[1])
    return ["#{name}: #{match[1]} is not a real calendar date"] unless file_date

    data = front_matter(text)
    return ["#{name}: missing front matter (Jekyll will not treat it as a post)"] if data.nil?

    errors = []
    errors << "#{name}: front matter has no title" if blank?(data["title"])

    if blank?(data["date"])
      errors << "#{name}: front matter has no date"
    else
      fm_date = parse_date(data["date"])
      if fm_date.nil?
        errors << "#{name}: front matter date #{data["date"].inspect} is not a valid date"
      elsif fm_date != file_date
        errors << "#{name}: front matter date #{fm_date} does not match filename date #{file_date}"
      end
    end

    if !future_allowed && file_date > today
      errors << "#{name}: dated #{file_date}, which is in the future, so GitHub Pages will not publish it yet"
    end

    errors
  rescue InvalidFrontMatter => e
    ["#{name}: #{e.message}"]
  end

  def parse_date(value)
    case value
    when Time then value.to_date
    when Date then value
    when String then Date.strptime(value[0, 10], "%Y-%m-%d")
    end
  rescue Date::Error
    nil
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
