# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
require File.join(File.dirname(__FILE__), "lib/deprecation/version")
Gem::Specification.new do |s|
  s.name = "deprecation"
  s.version = Deprecation::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chris Beer"]
  s.email = ["chris@cbeer.info"]
  s.summary = %q{Stand-alone deprecation library borrowed from ActiveSupport::Deprecation}
  s.description = %q{Stand-alone deprecation library borrowed from ActiveSupport::Deprecation}
  s.homepage = "http://github.com/cbeer/deprecation"
  s.license = "MIT"

  s.required_ruby_version = '>= 2.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activesupport"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ">= 2.14"
  s.add_development_dependency "bundler", ">= 1.0.14"
end
