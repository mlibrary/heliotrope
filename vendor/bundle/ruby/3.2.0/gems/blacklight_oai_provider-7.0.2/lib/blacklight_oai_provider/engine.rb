require 'blacklight'
require 'blacklight_oai_provider'
require 'rails'

module BlacklightOaiProvider
  class Engine < Rails::Engine
    # Add XSL Stylesheet to list of assets to be precompiled.
    initializer "blacklight_oai_provider.assets.precompile" do |app|
      app.config.assets.precompile += %w[blacklight_oai_provider/oai2.xsl]
    end

    # Load rake tasks.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('railties', '*.rake')).each do |railtie|
          load railtie
        end
      end
    end
  end
end
