# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'engine_cart'
EngineCart.load_application!

require 'blacklight-access_controls'

require 'factory_bot_rails'
require 'database_cleaner'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.include SolrSupport

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
