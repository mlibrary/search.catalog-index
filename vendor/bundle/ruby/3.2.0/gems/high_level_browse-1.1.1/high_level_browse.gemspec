lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "high_level_browse/version"

Gem::Specification.new do |spec|
  spec.name = "high_level_browse"
  spec.version = HighLevelBrowse::VERSION
  spec.authors = ["Bill Dueber"]
  spec.email = ["bill@dueber.com"]
  spec.summary = "Map LC call numbers to academic categories."
  spec.homepage = ""
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~>1.0"

  spec.add_development_dependency "bundler", "~>2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~>3.0"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "pry"
end
