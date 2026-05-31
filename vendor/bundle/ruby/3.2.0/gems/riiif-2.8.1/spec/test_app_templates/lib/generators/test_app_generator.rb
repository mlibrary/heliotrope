require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  # source_root 'spec/test_app_templates'
  source_root File.expand_path("../../../spec", __dir__)

  def add_routes
    route "mount Riiif::Engine => '/images', as: 'riiif'"
  end

  def copy_fixtures
    directory 'fixtures', 'spec/fixtures'
  end
end
