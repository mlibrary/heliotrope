# frozen_string_literal: true

require 'noid-rails'
require 'noid'
require 'yaml'

namespace :noid do
  namespace :rails do
    namespace :migrate do
      desc 'Migrate minter state file from YAML to Marshal'
      task :yaml_to_marshal do
        statefile = ENV.fetch('RAILS_NOID_STATEFILE', Noid::Rails.config.statefile)
        raise "File not found: #{statefile}\nAborting" unless File.exist?(statefile)
        puts "Migrating #{statefile} from YAML to Marshal serialization..."
        File.open(statefile, 'a+b', 0o644) do |f|
          f.flock(File::LOCK_EX)
          f.rewind
          begin
            yaml_state = YAML.safe_load(f)
          rescue Psych::SyntaxError
            raise "File not valid YAML: #{statefile}\nAborting."
          end
          minter = Noid::Minter.new(yaml_state)
          f.truncate(0)
          new_state = Marshal.dump(minter.dump)
          f.write(new_state)
        end
        puts 'Done!'
      end

      desc 'Migrate minter state from file to database'
      task file_to_database: :environment do
        statefile = ENV.fetch('RAILS_NOID_STATEFILE', Noid::Rails.config.statefile)
        raise "File not found: #{statefile}\nAborting" unless File.exist?(statefile)
        puts "Migrating #{statefile} to database..."
        state = Noid::Rails::Minter::File.new.read
        minter = Noid::Minter.new(state)
        new_state = Noid::Rails::Minter::Db.new
        new_state.write!(minter)
        puts 'Done!'
      end

      desc 'Migrate minter state from database to file'
      task database_to_file: :environment do
        statefile = ENV.fetch('RAILS_NOID_STATEFILE', Noid::Rails.config.statefile)
        if File.exist?(statefile)
          raise "File already exists (delete it first if it's not valuable): " \
                "#{statefile}\nAborting"
        end
        puts "Migrating minter state from database to #{statefile}..."
        state = Noid::Rails::Minter::Db.new.read
        minter = Noid::Minter.new(state)
        new_state = Noid::Rails::Minter::File.new
        new_state.write!(minter)
        puts 'Done!'
      end
    end
  end
end
