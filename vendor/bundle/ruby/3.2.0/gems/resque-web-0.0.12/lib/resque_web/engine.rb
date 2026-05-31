require 'twitter-bootstrap-rails'
require 'font-awesome-sass'
require 'jquery-rails'

module ResqueWeb
  class Engine < ::Rails::Engine
    isolate_namespace ResqueWeb

    initializer "resque_web.assets.precompile" do |app|
      app.config.assets.precompile += %w(resque_web/*.png)
    end
  end
  module Plugins
    def self.plugins
      self.constants.map{|m| self.const_get(m)}
    end
  end
end
