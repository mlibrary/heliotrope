require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # if you need to generate any additional configuration
  # into the test app, this generator will be run immediately
  # after setting up the application

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight:install', '--devise'
    generate 'blacklight:test_support'
  end

  def change_migrations_if_rails_4_2
    return unless Rails.version =~ /^4.2.*/

    say_status('warning', 'OVERRIDING BLACKLIGHT MIGRATION FOR RAILS 4.2', :yellow)
    migrations = Rails.root.join('db', 'migrate', '*.rb')
    Dir.glob(migrations).each do |m|
      text = File.read(m).gsub(/ActiveRecord::Migration\[[\d\.]+\]/, 'ActiveRecord::Migration')
      File.open(m, 'w').write(text)
    end
  end

  # Add favicon.ico to asset path
  # ADD THIS LINE Rails.application.config.assets.precompile += %w( favicon.ico )
  # TO config/assets.rb
  def add_favicon_to_asset_path
    say_status("warning", "ADDING FAVICON TO ASSET PATH", :yellow)

    append_to_file 'config/initializers/assets.rb' do
      'Rails.application.config.assets.precompile += %w( favicon.ico )'
    end
  end

  # Override solr.yml to match settings needed for solr_wrapper.
  def update_solr_config
    [:solr, :blacklight].each do |key|
      say_status("warning", "COPYING #{key}.YML".upcase, :yellow)

      remove_file "config/#{key}.yml"
      copy_file "config/solr.yml", "config/#{key}.yml"
    end
  end

  def install_engine
    say_status("warning", "GENERATING BL OAI PLUGIN", :yellow)

    generate 'blacklight_oai_provider:install'
  end

  def add_test_blacklight_oai_controller_config
    %w[catalog alternate].each { |cn| add_test_config_for(cn) }
  end

  def add_test_blacklight_oai_model_config
    insert_into_file "app/models/solr_document.rb", after: "include BlacklightOaiProvider::SolrDocument\n" do
      <<-CONFIG
  field_semantics.merge!(
    title: "title_tsim",
    date: "pub_date_ssim",
    subject: "subject_ssim",
    creator: "author_tsim",
    format: "format",
    language: "language_ssim",
  )
      CONFIG
    end
  end

  private

  def add_test_config_for(controller_basename)
    say_status("warning", "ADDING BL OIA-PMH CONFIG")

    insert_into_file "app/controllers/#{controller_basename}_controller.rb", after: "config.default_solr_params = {" do
      "\n      fl: '*',\n"
    end

    insert_into_file "app/controllers/#{controller_basename}_controller.rb", after: "  configure_blacklight do |config|\n" do
      <<-CONFIG
    config.default_document_solr_params = {
      qt: 'search',
      fl: '*',
      rows: 1,
      q: '{!raw f=id v=$id}'
    }
      CONFIG
    end

    insert_into_file "app/controllers/#{controller_basename}_controller.rb", after: "configure_blacklight do |config|\n" do
      <<-CONFIG
    config.oai = {
      provider: {
        repository_name: '#{controller_basename.titleize} Repository',
        repository_url: 'http://localhost/#{controller_basename}/oai',
        record_prefix: 'oai:test',
        admin_email: 'root@localhost',
        deletion_support: 'persistent',
        sample_id: '109660'
      },
      document: {
        set_fields: [
          { label: 'language', solr_field: 'language_ssim' }
        ],
        limit: 25
      }
    }
      CONFIG
    end
  end
end
