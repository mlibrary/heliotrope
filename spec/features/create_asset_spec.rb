# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Asset`
require 'rails_helper'
include Warden::Test::Helpers

# Use js: true to switch to the Capybara.javascript_driver (:selenium by default), or provide a :driver option to switch to one specific driver. For example:
# describe 'some stuff which requires js', js: true do
#   it 'will use the default js driver'
#   it 'will switch to one specific driver', :driver => :webkit
# end

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a Asset', js: true do
  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      AdminSet.find_or_create_default_admin_set_id
      login_as user
    end

    scenario do
      visit '/dashboard'
      click_link "Works"
      click_link "Add new work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Asset"
      click_button "Create work"

      expect(page).to have_content "Add New Asset"
    end
  end
end
