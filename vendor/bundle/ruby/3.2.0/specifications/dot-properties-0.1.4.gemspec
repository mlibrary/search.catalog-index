# -*- encoding: utf-8 -*-
# stub: dot-properties 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "dot-properties".freeze
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael B. Klein".freeze]
  s.date = "2022-01-20"
  s.description = "Java-style .properties file manipulation with a light touch".freeze
  s.email = ["mbklein@gmail.com".freeze]
  s.homepage = "https://github.com/mbklein/dot-properties".freeze
  s.licenses = ["APACHE2".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Read/write .properties files, respecting comments and existing formatting as much as possible".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bundler>.freeze, [">= 2.2.33"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 2.4.2"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
end
