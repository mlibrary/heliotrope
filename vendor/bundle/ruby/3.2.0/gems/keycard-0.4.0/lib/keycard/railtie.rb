# frozen_string_literal: true

# Railtie to hook Keycard into Rails applications.
#
# This does three things at present:
#
#   1. Loads our rake tasks, so you can run keycard:migrate from the app.
#   2. Pulls the Rails database information off of the ActiveRecord
#      connection and puts it on Keycard::DB.config before any application
#      initializers are run.
#   3. Sets up the Keycard database connection after application
#      initializers have run, if it has not already been done and we are not
#      running as a Rake task. This condition is key because when we are in
#      rails server or console, we want to initialize!, but when we are in
#      a rake task to update the database, we have to let it connect, but
#      not initialize.
class Keycard::Railtie < Rails::Railtie
  railtie_name :keycard

  class << self
    # Register a callback to run before anything in 'config/initializers' runs.
    # The block will get a reference to Keycard::DB.config as its only parameter.
    def before_initializers(&block)
      before_blocks << block
    end

    # Register a callback to run after anything in 'config/initializers' runs.
    # The block will get a reference to Keycard::DB.config as its only parameter.
    # Keycard::DB.initialize! will not have been automatically called at this
    # point, so this is an opportunity to do so if an initializer has not.
    def after_initializers(&block)
      after_blocks << block
    end

    # Register a callback to run when Keycard is ready and fully initialized.
    # This will happen once in production, and on each request in development.
    # If you need to do something once in development, you can choose between
    # keeping a flag or using the after_initializers.
    def when_keycard_is_ready(&block)
      ready_blocks << block
    end

    def before_blocks
      @before_blocks ||= []
    end

    def after_blocks
      @after_blocks ||= []
    end

    def ready_blocks
      @ready_blocks ||= []
    end

    def under_rake!
      @under_rake = true
    end

    def under_rake?
      @under_rake ||= false
    end
  end

  # This runs before anything in 'config/initializers' runs.
  initializer "keycard.before_initializers", before: :load_config_initializers do
    config = Keycard::DB.config
    unless config.url
      case Rails.env
      when "development"
        config[:opts] = {adapter: "sqlite", database: "db/keycard_development.sqlite3"}
      when "test"
        config[:opts] = {adapter: "sqlite"}
      end
    end

    self.class.before_blocks.each do |block|
      block.call(config.to_h)
    end
  end

  # This runs after everything in 'config/initializers' runs.
  initializer "keycard.after_initializers", after: :load_config_initializers do
    config = Keycard::DB.config
    raise "Keycard::DB.config must be configured" unless config.url || config.opts
    self.class.after_blocks.each do |block|
      block.call(config.to_h)
    end

    Keycard::DB.initialize! unless self.class.under_rake?

    self.class.ready_blocks.each do |block|
      block.call(Keycard::DB.db)
    end
  end

  def rake_files
    base = Pathname(__dir__) + "../tasks/"
    [base + "migrate.rake"]
  end

  rake_tasks do
    self.class.under_rake!
    rake_files.each { |file| load file }
  end
end
