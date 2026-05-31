# frozen_string_literal: true
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'yaml'
require_relative 'spec/support/database_connection.rb'
require 'active_record'
require 'rubocop/rake_task'
load 'tasks/dev.rake'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Run RuboCop style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end

namespace :db do
  task :environment do
    path = File.join(File.dirname(__FILE__), './db/migrate')
    migrations_paths = [path]
    DATABASE_ENV = ENV['RACK_ENV'] || 'test'
    MIGRATIONS_DIR = ENV['MIGRATIONS_DIR'] || migrations_paths
  end

  task configuration: :environment do
    @config = YAML.safe_load(ERB.new(File.read("db/config.yml")).result, aliases: true)[DATABASE_ENV]
  end

  task configure_connection: :configuration do
    DatabaseConnection.connect!(DATABASE_ENV)
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
    @config = if ::ActiveRecord::Base.configurations.respond_to?(:configs_for)
                ::ActiveRecord::Base.configurations.configs_for(env_name: DATABASE_ENV.to_s)[0]
              else
                ::ActiveRecord::Base.configurations[DATABASE_ENV.to_s]
              end
  end

  desc 'Create the database from db/config.yml for the current DATABASE_ENV'
  task create: :configure_connection do
    begin
      database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(@config)
      database.create
    rescue
      puts "Database already exists."
    end
    puts "Database created"
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task drop: :configure_connection do
    database = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(@config)
    database.drop
    puts "Database dropped"
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task migrate: :configure_connection do
    verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    scope   = ENV['SCOPE']
    verbose_was = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = verbose
    if ActiveRecord::Migrator.respond_to?(:migrate)
      ActiveRecord::Migrator.migrate(MIGRATIONS_DIR, version) do |migration|
        scope.blank? || scope == migration.scope
      end
    else
      ActiveRecord::Base.connection.migration_context.migrate(version) do |migration|
        scope.blank? || scope == migration.scope
      end
    end
    ActiveRecord::Base.clear_cache!
  ensure
    ActiveRecord::Migration.verbose = verbose_was
  end

  namespace :schema do
    task :load do
      Rake::Task["db:migrate"].invoke
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task rollback: :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback(MIGRATIONS_DIR, step)
  end
end
