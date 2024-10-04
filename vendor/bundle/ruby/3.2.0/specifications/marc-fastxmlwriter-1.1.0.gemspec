# -*- encoding: utf-8 -*-
# stub: marc-fastxmlwriter 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "marc-fastxmlwriter".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2022-05-02"
  s.email = ["bill@dueber.com".freeze]
  s.homepage = "https://github.com/billdueber/marc-fastxmlwriter".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Faster (but unverified) MARC-XML from a MARC Record".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<marc>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.0"])
end
