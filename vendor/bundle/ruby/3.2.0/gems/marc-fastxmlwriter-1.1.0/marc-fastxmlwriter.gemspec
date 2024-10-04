lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "marc/fastxmlwriter/version"

Gem::Specification.new do |spec|
  spec.name = "marc-fastxmlwriter"
  spec.version = Marc::FastXMLWriter::VERSION
  spec.authors = ["Bill Dueber"]
  spec.email = ["bill@dueber.com"]
  spec.summary = "Faster (but unverified) MARC-XML from a MARC Record"
  spec.homepage = "https://github.com/billdueber/marc-fastxmlwriter"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "marc", "~>1.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~>13"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "nokogiri", "~> 1.0"
end
