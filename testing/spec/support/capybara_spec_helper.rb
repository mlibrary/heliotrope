# frozen_string_literal: true

require 'capybara/rspec'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
end

RSpec.configure do |config|
  config.include Capybara::DSL
end

module CapybaraSpecHelper
end
