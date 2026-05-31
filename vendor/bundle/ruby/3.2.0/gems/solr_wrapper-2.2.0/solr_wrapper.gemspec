# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'solr_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "solr_wrapper"
  spec.version       = SolrWrapper::VERSION
  spec.authors       = ["Chris Beer"]
  spec.email         = ["chris@cbeer.info"]
  spec.summary       = %q{Solr 5 service wrapper}
  spec.homepage      = "https://github.com/cbeer/solr_wrapper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "rubyzip"
  spec.add_dependency "ruby-progressbar"
  spec.add_dependency "retriable"

  spec.add_development_dependency "bundler", ">= 1.7", "< 3"
  spec.add_development_dependency "rake", "~> 10.0", "< 13"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simple_solr_client", "= 0.2.0" # 0.2.1 removed support for schema retrieval
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "webmock"
end
