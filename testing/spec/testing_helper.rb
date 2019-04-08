# frozen_string_literal: true

require 'spec_helper'

require_relative '../testing'
require_relative './support/capybara_spec_helper'

RSpec.configure do |config|
  config.include CapybaraSpecHelper, type: :capybara
end
