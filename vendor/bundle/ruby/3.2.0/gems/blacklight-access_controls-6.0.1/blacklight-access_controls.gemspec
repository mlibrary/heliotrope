version = File.read(File.expand_path('../VERSION', __FILE__)).strip

module Blacklight
  module AccessControls
    def self.bl_version
      ENV['BLACKLIGHT_VERSION'] ? [ENV['BLACKLIGHT_VERSION']] : ['> 6.0', '< 8']
    end
  end
end

Gem::Specification.new do |gem|
  gem.name          = 'blacklight-access_controls'

  gem.description   = 'Access controls for blacklight-based applications'
  gem.summary       = 'Access controls for blacklight-based applications'
  gem.homepage      = 'https://github.com/projectblacklight/blacklight-access_controls'
  gem.email         = ['blacklight-development@googlegroups.com']
  gem.authors       = ['Chris Beer', 'Justin Coyne', 'Matt Zumwalt', 'Valerie Maher']

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.version       = version
  gem.license       = 'APACHE2'

  gem.required_ruby_version = '>= 2.1.0'

  gem.add_dependency 'blacklight', *Blacklight::AccessControls.bl_version
  gem.add_dependency 'cancancan', '>= 1.8'
  gem.add_dependency 'deprecation', '~> 1.0'

  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'engine_cart', '~> 2.2'
  gem.add_development_dependency 'factory_bot_rails', '~> 4.8'
  gem.add_development_dependency 'rake', '~> 12.3'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rubocop', '~> 0.52.1'
  gem.add_development_dependency 'rubocop-rspec'
  gem.add_development_dependency 'solr_wrapper'
end
