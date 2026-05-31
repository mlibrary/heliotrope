module HydraEditor
  class Engine < ::Rails::Engine
    require 'simple_form'
    require 'sprockets/es6'
    require 'almond-rails'
    require 'hydra/head'

    engine_name 'hydra_editor'
    config.eager_load_paths += %W[
       #{config.root}/app/helpers/concerns
       #{config.root}/app/presenters
    ]
    initializer 'hydra-editor.initialize' do
      require 'cancan'
      Sprockets::ES6.configuration = { 'modules' => 'amd', 'moduleIds' => true }
    end
  end
end
