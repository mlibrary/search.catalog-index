# -*- encoding: utf-8 -*-
# stub: high_level_browse 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "high_level_browse".freeze
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2022-06-20"
  s.email = ["bill@dueber.com".freeze]
  s.executables = ["fetch_new_hlb".freeze, "hlb".freeze, "test_marc_file_for_hlb".freeze]
  s.files = ["bin/fetch_new_hlb".freeze, "bin/hlb".freeze, "bin/test_marc_file_for_hlb".freeze]
  s.homepage = "".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Map LC call numbers to academic categories.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<standard>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
end
