# frozen_string_literal: true

module Blacklight
  class AccessControlsGenerator < Rails::Generators::Base
    desc "This generator makes the following changes to your application:
1. Includes Blacklight::AccessControls::User in the User class.
2. Includes Blacklight::AccessControls::Enforcement in the SearchBuilder class.
3. Adds access controls to CatalogController.
4. Adds Ability class."

    source_root File.expand_path('..', __FILE__)

    class_option :user_model, aliases: '-m',
                              type: :string, default: 'User',
                              desc: 'What is your user model called?'

    class_option :search_builders, aliases: '-b', type: :array,
                                   default: Array(File.join('app', 'models', 'search_builder.rb')),
                                   desc: 'The path(s) to your search builder model(s)'

    def add_access_controls_to_user
      say_status('status', 'ADDING ACCESS CONTROLS TO USER MODEL', :yellow)
      insert_into_file File.join('app', 'models', "#{options[:user_model].underscore}.rb"),
                       "  include Blacklight::AccessControls::User\n\n",
                       after: "include Blacklight::User\n"
    end

    def add_access_controls_to_catalog_controller
      say_status('status', 'ADDING ACCESS CONTROLS TO CATALOG CONTROLLER', :yellow)

      string_to_insert = <<-ADDITIONS
  include Blacklight::AccessControls::Catalog

  # Apply the blacklight-access_controls
  before_action :enforce_show_permissions, only: :show

      ADDITIONS

      insert_into_file 'app/controllers/catalog_controller.rb',
                       string_to_insert, after: "include Blacklight::Catalog\n"
    end

    def add_cancan_ability
      say_status('status', 'ADDING CANCAN ABILITY', :yellow)
      copy_file 'ability.rb', 'app/models/ability.rb'
    end

    def add_configuration
      say_status('status', 'ADDING BLACKLIGHT ACCESS CONTROLS CONFIGURATION', :yellow)
      copy_file 'blacklight_access_controls.rb', 'config/initializers/blacklight_access_controls.rb'
    end
  end
end
