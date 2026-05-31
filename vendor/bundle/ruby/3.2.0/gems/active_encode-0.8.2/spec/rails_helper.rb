# frozen_string_literal: true
require 'spec_helper'

require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
ActiveJob::Base.queue_adapter = :test

require 'database_cleaner'

RSpec.configure do |config|
  config.before do |example|
    if example.metadata[:db_clean]
      DatabaseCleaner.clean_with(:truncation)
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.after do |example|
    DatabaseCleaner.clean if example.metadata[:db_clean]
  end
end
