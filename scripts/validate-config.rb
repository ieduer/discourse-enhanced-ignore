# frozen_string_literal: true

# Static checks that need no Discourse checkout: metadata, settings and
# locale files parse, agree with each other, and every translation key used
# in the source exists.
require "json"
require "yaml"

root = File.expand_path("..", __dir__)
errors = []

about = JSON.parse(File.read(File.join(root, "about.json")))
%w[name about_url license_url theme_version].each do |key|
  errors << "about.json: missing #{key}" if about[key].to_s.empty?
end
errors << "about.json: component must be true" unless about["component"] == true
errors << "about.json: name contains TODO" if about.to_s.include?("TODO")

settings = YAML.safe_load_file(File.join(root, "settings.yml"))
locale = YAML.safe_load_file(File.join(root, "locales/en.yml"))
errors << "locales/en.yml: top-level key must be en" unless locale.keys == ["en"]
en = locale.fetch("en")

described = en.dig("theme_metadata", "settings") || {}
(settings.keys - described.keys).each { |key| errors << "setting #{key} has no description" }
(described.keys - settings.keys).each { |key| errors << "description for unknown setting #{key}" }
if en.dig("theme_metadata", "description").to_s.empty?
  errors << "theme_metadata.description missing"
end

sources = Dir.glob(File.join(root, "javascripts/**/*.{js,gjs}"))
used = sources.flat_map { |file| File.read(file).scan(/themePrefix\(?\s*"([^"]+)"/).flatten }.uniq
used.each do |key|
  value = en.dig(*key.split("."))
  errors << "translation #{key} is used but not defined" if value.nil?
end

defined = []
walk = ->(node, path) do
  node.each do |key, value|
    next if path.empty? && key == "theme_metadata"
    if value.is_a?(Hash) && !(value.keys - %w[zero one two few many other]).empty?
      walk.call(value, path + [key])
    else
      defined << (path + [key]).join(".")
    end
  end
end
walk.call(en, [])
(defined - used).each { |key| errors << "translation #{key} is defined but never used" }

sources.each do |file|
  File
    .read(file)
    .scan(/settings\.([a-z_]+)/)
    .flatten
    .uniq
    .each do |key|
      errors << "#{File.basename(file)} reads unknown setting #{key}" unless settings.key?(key)
    end
end

if errors.empty?
  puts "config OK: #{settings.size} setting(s), #{used.size} translation key(s), theme_version #{about["theme_version"]}"
else
  warn errors.join("\n")
  exit 1
end
