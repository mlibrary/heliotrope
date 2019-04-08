# frozen_string_literal: true

require 'testing_helper'

RSpec.describe "Presses Index", type: :capybara do
  before do
    Capybara.run_server = false
    Capybara.default_max_wait_time = 15
    Capybara.server_host = 'web'
    Capybara.app_host = Testing::Target.url
  end

  it "index" do
    visit "presses"
    click_link "Testing Press"
    expect(page).to have_content("Testing Press dedicated to automated systems tests.")
    click_link "Log In"
    expect(page).to have_content("Enter your Login ID and Password")
    # Huston we have a problem ... Shibboleth.
  end
end
