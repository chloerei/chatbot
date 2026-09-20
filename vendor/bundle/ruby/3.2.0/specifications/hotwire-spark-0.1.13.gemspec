# -*- encoding: utf-8 -*-
# stub: hotwire-spark 0.1.13 ruby lib

Gem::Specification.new do |s|
  s.name = "hotwire-spark".freeze
  s.version = "0.1.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/hotwired/spark", "homepage_uri" => "https://github.com/hotwired/spark", "source_code_uri" => "https://github.com/hotwired/spark" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jorge Manrubia".freeze]
  s.date = "2025-01-25"
  s.description = "A live reloading system that updates just what's needed to offer a smooth experience.".freeze
  s.email = ["jorge@37signals.com".freeze]
  s.homepage = "https://github.com/hotwired/spark".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Smooth live reloading for your Rails apps".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0.0"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<listen>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop-rails-omakase>.freeze, [">= 0"])
  s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
  s.add_development_dependency(%q<cuprite>.freeze, [">= 0"])
end
