# -*- encoding: utf-8 -*-
# stub: match_map 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "match_map".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2013-10-11"
  s.description = "MatchMap is a map representing key=>value pairs but where \n    (a) a query argument can match more than one key, and (b) the argument is compraed to the key\n    such that you can use regex patterns as keys".freeze
  s.email = "bill@dueber.com".freeze
  s.homepage = "http://github.com/billdueber/match_map".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A multimap that allows keys to match regex patterns".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0"])
end
