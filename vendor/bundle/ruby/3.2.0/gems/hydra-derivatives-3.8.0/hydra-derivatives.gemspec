version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = "hydra-derivatives"
  spec.version       = version
  spec.authors       = ["Justin Coyne"]
  spec.email         = ["jenlindner@gmail.com", "jcoyne85@stanford.edu"]
  spec.description   = "Derivative generation plugin for hydra"
  spec.summary       = "Derivative generation plugin for hydra"
  spec.license       = "APACHE2"
  spec.homepage      = "https://github.com/projecthydra/hydra-derivatives"
  spec.metadata      = { "rubygems_mfa_required" => "true" }

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR).select { |f| File.dirname(f) !~ %r{\A"?spec|test|features\/?} }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'fcrepo_wrapper', '~> 0.2'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rails', '> 5.1', '< 7.1'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency "solr_wrapper"

  spec.add_dependency 'active_encode', '~> 0.1'
  spec.add_dependency 'active-fedora', '>= 14.0'
  spec.add_dependency 'active-triples', '>= 1.2'
  spec.add_dependency 'activesupport', '>= 4.0', '< 7.1'
  spec.add_dependency 'addressable', '~> 2.5'
  spec.add_dependency 'deprecation'
  spec.add_dependency 'mime-types', '> 2.0', '< 4.0'
  spec.add_dependency 'mini_magick', '>= 3.2', '< 5'
end
