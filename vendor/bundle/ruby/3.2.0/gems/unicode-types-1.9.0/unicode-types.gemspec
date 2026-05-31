# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/unicode/types/constants"

Gem::Specification.new do |gem|
  gem.name          = "unicode-types"
  gem.version       = Unicode::Types::VERSION
  gem.summary       = "Determines the very basic type of a code point"
  gem.description   = "[Unicode #{Unicode::Types::UNICODE_VERSION}] Determines the very basic type of codepoints (one of: Graphic, Format, Control, Private-use, Surrogate, Noncharacter, Reserved)"
  gem.authors       = ["Jan Lelis"]
  gem.email         = ["hi@ruby.consulting"]
  gem.homepage      = "https://github.com/janlelis/unicode-types"
  gem.license       = "MIT"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^pkg/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.metadata      = { "rubygems_mfa_required" => "true" }

  gem.required_ruby_version = ">= 2.0"
end
