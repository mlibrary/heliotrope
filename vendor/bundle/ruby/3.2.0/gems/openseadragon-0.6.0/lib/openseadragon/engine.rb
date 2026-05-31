module Openseadragon
  class Engine < ::Rails::Engine
    isolate_namespace Openseadragon

    initializer 'openseadragon.assets.precompile' do |app|
      app.config.assets.precompile += %w[openseadragon/*.png]
    end
  end
end
