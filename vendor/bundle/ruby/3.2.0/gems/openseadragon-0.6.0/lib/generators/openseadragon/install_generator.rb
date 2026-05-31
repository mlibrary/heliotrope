require 'rails/generators'

module Openseadragon
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def assets
      copy_file "openseadragon.css", "app/assets/stylesheets/openseadragon.css"
      copy_file "openseadragon.js", "app/assets/javascripts/openseadragon.js"

      if File.exist? 'app/assets/config/manifest.js'
        append_to_file 'app/assets/config/manifest.js', "\n//= link openseadragon-assets\n"
      end
    end

    def inject_helper
      inject_into_class 'app/controllers/application_controller.rb', ApplicationController do
        "  helper Openseadragon::OpenseadragonHelper\n"
      end
    end
  end
end
