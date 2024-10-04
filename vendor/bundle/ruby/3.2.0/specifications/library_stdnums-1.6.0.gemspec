# -*- encoding: utf-8 -*-
# stub: library_stdnums 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "library_stdnums".freeze
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bill Dueber".freeze]
  s.date = "2017-05-04"
  s.email = ["none@nowhere.org".freeze]
  s.homepage = "https://github.com/billdueber/library_stdnums".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A simple set of module functions to normalize, validate, and convert common library standard numbers".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 11.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<yard>.freeze, [">= 0.9.5"])
end
