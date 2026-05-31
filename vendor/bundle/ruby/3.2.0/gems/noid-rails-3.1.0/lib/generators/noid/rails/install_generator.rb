# frozen_string_literal: true

module Noid
  module Rails
    # Generates the migrations into the host application
    class InstallGenerator < ::Rails::Generators::Base
      source_root ::File.expand_path('../templates', __FILE__)

      desc <<~DESCRIPTION
        Copies DB migrations
      DESCRIPTION

      def banner
        say_status('info', 'Installing noid-rails', :blue)
      end

      def migrations
        rake 'noid_rails_engine:install:migrations'
      end
    end
  end
end
