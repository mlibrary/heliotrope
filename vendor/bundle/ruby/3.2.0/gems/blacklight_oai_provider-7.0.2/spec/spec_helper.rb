ENV["RAILS_ENV"] ||= 'test'
require 'rsolr'
require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'webdrivers'

Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
end
