# frozen_string_literal: true

module Noid
  module Rails
    # Initializes the database with a noid namespace
    class SeedGenerator < ::Rails::Generators::Base
      source_root ::File.expand_path('../templates', __FILE__)
      argument :namespace, type: :string, default: Noid::Rails.config.namespace
      argument :template, type: :string, default: Noid::Rails.config.template

      desc <<~DESCRIPTION
        Seeds DB from Noid::Rails.config (or command-line overrides)
      DESCRIPTION

      def banner
        say_status('info', "Initializing database table for namespace:template of '#{namespace}:#{template}'", :blue)
      end

      def checks
        if namespace != Noid::Rails.config.namespace
          say_status('warn', 'Be sure to use an initializer to do ' \
                             "'Noid::Rails.config.namespace = #{namespace}'", :red)
        end
        return if template == Noid::Rails.config.template
        say_status('warn', 'Be sure to use an initializer to do ' \
                           "Noid::Rails.config.template = #{template}'", :red)
      end

      def seed_row
        MinterState.seed!(
          namespace: namespace,
          template: template
        )
      end
    end
  end
end
