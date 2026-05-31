# frozen_string_literal: true

require "bundler/setup"
require "checkpoint"

if defined?(Rails)
  # When db:schema:dump is called directly, we can tack this on.
  # If we do it unconditionally, db:migrate will try to dump before we have
  # been able to migrate the checkpoint tables.
  if Rake.application.top_level_tasks.include?("db:schema:dump")
    Rake::Task["db:schema:dump"].enhance do
      Rake::Task["checkpoint:schema:dump"].invoke
    end
  end

  # Run our schema load to make sure that the version number is stored in
  # schema_info, so migrations don't try to double-run. The actual table
  # structure is handled by the Rails schema:dump and schema:load.
  # A db:setup will trigger this, so we don't have to handle it separately.
  Rake::Task["db:schema:load"].enhance do
    Rake::Task["checkpoint:schema:load"].invoke
  end

  # We hook into db:migrate for convenience.
  Rake::Task["db:migrate"].enhance do
    Rake::Task["checkpoint:migrate"].invoke
  end

end

namespace :checkpoint do
  desc "Migrate the Checkpoint database to the latest version"
  task :migrate do
    if defined?(Rails)
      # Load the 'environment', which does the full Rails initialization.
      # The Railtie is smart enough to know whether we are in a Rake task,
      # so it can avoid initializing and we can migrate safely before the
      # models are loaded.
      Rake::Task["environment"].invoke
    end

    # After migrating, we initialize here, even though it isn't strictly
    # necessary, but it will ensure that migration does a small sanity check
    # that at least all of the tables expected by model classes exist.
    Checkpoint::DB.migrate!
    Checkpoint::DB.initialize!
  end

  # We don't bother defining the schema:dump and schema:load tasks if we're
  # not running under Rails. They exist only to cooperate with the dumps done
  # by Rails, since schema.rb includes any Checkpoint tables in the same
  # database as the application -- a convenient default mode.
  if defined?(Rails)
    namespace :schema do
      desc "Dump the Checkpoint version to db/checkpoint.yml"
      task :dump do
        Rake::Task["environment"].invoke
        Checkpoint::DB.dump_schema!
      end

      desc "Load the Checkpoint version from db/checkpoint.yml"
      task :load do
        Rake::Task["environment"].invoke
        Checkpoint::DB.load_schema!
      end

      # When running under Rails, we dump the schema after migrating so
      # everything stays synced up for db:setup against a new database.
      # Rake::Task['checkpoint:schema:dump'].invoke
      Rake::Task["checkpoint:migrate"].enhance do
        Rake::Task["checkpoint:schema:dump"].invoke
      end
    end
  end
end
