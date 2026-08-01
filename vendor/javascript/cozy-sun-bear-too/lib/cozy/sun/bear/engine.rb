module Cozy
  module Sun
    module Bear
      class Engine < Rails::Engine
      	# set up paths; this brings over the fonts automatically
        config.assets.paths << File.expand_path("../../../../../dist", __FILE__)
        config.assets.paths << File.expand_path("../../../../../vendor", __FILE__)
        # config.assets.precompile << "cozy-sun-bear.js"
        # config.assets.precompile << "cozy-sun-bear.css"
        config.assets.precompile << "javascripts/engines/epub.js*"
        config.assets.precompile << "javascripts/engines/epub.legacy.js*"
      end
    end
  end
end
