# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'match_map/version'


Gem::Specification.new do |gem|
  gem.name = "match_map"
  gem.version = MatchMap::VERSION
  gem.summary = "A multimap that allows keys to match regex patterns"
  gem.description = "MatchMap is a map representing key=>value pairs but where \n    (a) a query argument can match more than one key, and (b) the argument is compraed to the key\n    such that you can use regex patterns as keys"
  gem.license       = "MIT"
  gem.authors       = ["Bill Dueber"]
  gem.email         = "bill@dueber.com"
  gem.homepage = "http://github.com/billdueber/match_map"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  
  gem.add_development_dependency 'bundler', '~> 1.0'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'


end

