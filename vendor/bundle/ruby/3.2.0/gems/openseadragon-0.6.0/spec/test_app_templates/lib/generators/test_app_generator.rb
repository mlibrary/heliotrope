require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def run_generator
    generate 'openseadragon:install'
  end

  def generate_controller
    generate 'controller test show'
    route "root to: 'test#show'"
  end

  def configure_test_assets
    insert_into_file 'config/environments/test.rb', :after => 'Rails.application.configure do' do
      %q{
  config.assets.digest = false
}
    end
  end

  def add_osd_to_view
    copy_file "show.html.erb", 'app/views/test/show.html.erb', force: true
  end
end
